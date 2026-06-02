module Evolution
  class MessageUpsertProcessor
    ALLOWED_MESSAGE_TYPES = %w[
      conversation extendedTextMessage
      imageMessage audioMessage documentMessage videoMessage stickerMessage
      contactMessage locationMessage
    ].freeze

    AUDIO_MIMETYPES = %w[audio/ogg audio/mpeg audio/mp4 audio/aac audio/webm audio].freeze

    def initialize(instance_name, data)
      @instance_name = instance_name
      @data          = data.is_a?(Hash) ? data.deep_symbolize_keys : {}
    end

    def call
      return unless @instance_name&.start_with?("zavy-")

      workspace_id = @instance_name.split("-")[1].to_i
      return unless workspace_id > 0

      workspace = Workspace.find_by(id: workspace_id)
      return unless workspace

      wi = workspace.whatsapp_instances.find_by(instance_id: @instance_name)
      return unless wi

      msg_data = Array(@data.dig(:messages)).first || @data
      return if msg_data.blank?

      msg_type = msg_data[:messageType].to_s
      return if msg_type.present? && !ALLOWED_MESSAGE_TYPES.include?(msg_type)

      evolution_id = msg_data.dig(:key, :id)
      return if evolution_id.blank?

      # Deduplicação
      if Message.exists?(workspace: workspace, source_id: evolution_id)
        Rails.logger.info "[Evolution] Duplicate skipped: source_id=#{evolution_id}"
        return
      end

      from_me       = msg_data.dig(:key, :fromMe) == true
      sender_jid    = msg_data.dig(:key, :remoteJid).to_s
      sender_digits = sender_jid.split("@").first.gsub(/[^0-9]/, "")
      phone         = "+#{sender_digits}"
      push_name     = msg_data[:pushName].presence || phone

      text_content = extract_text(msg_data)
      quoted_id    = extract_quoted_id(msg_data)
      attachment   = extract_attachment(msg_data)

      contact = find_or_create_contact(workspace, phone, push_name)
      card    = find_or_create_card(workspace, wi, contact)
      return unless card

      message = persist_message(
        workspace:    workspace,
        card:         card,
        contact:      contact,
        evolution_id: evolution_id,
        content:      text_content,
        attachment:   attachment,
        from_me:      from_me,
        sender_name:  push_name,
        sender_phone: phone,
        quoted_id:    quoted_id
      )
      return unless message

      emit_card_event(workspace, card, message, from_me)
      broadcast(card, message)
    rescue => e
      Rails.logger.error "[Evolution] MessageUpsertProcessor error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    end

    private

    def find_or_create_contact(workspace, phone, name)
      contact = workspace.contacts.find_by(phone_number: phone)
      return contact if contact

      workspace.contacts.create!(
        name:         name,
        phone_number: phone
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[Evolution] Contact create failed #{phone}: #{e.message}"
      workspace.contacts.find_by(phone_number: phone)
    end

    def find_or_create_card(workspace, wi, contact)
      # Exige pipeline configurado na instância
      pipeline = wi.pipeline
      unless pipeline
        Rails.logger.warn "[Evolution] WhatsappInstance #{wi.instance_id} sem pipeline configurado"
        return nil
      end

      # Reutiliza card ativo com o mesmo número
      card = workspace.cards.active
                      .where(contact_phone: contact.phone_number)
                      .joins(:pipeline).where(pipelines: { id: pipeline.id })
                      .order(created_at: :desc)
                      .first
      return card if card

      stage = pipeline.stages.where(stage_type: "intermediate").order(:position).first ||
              pipeline.stages.order(:position).first
      return nil unless stage

      card = workspace.cards.create!(
        pipeline:         pipeline,
        stage:            stage,
        title:            contact.name,
        contact_name:     contact.name,
        contact_phone:    contact.phone_number,
        stage_changed_at: Time.current
      )

      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "card_created",
        payload:    { title: card.title, stage_id: stage.id, auto_created: true, source: "evolution_webhook" }
      )

      ActionCable.server.broadcast(
        "pipeline_#{pipeline.id}",
        { event: "card_created", card_id: card.id, title: card.title }
      )

      card
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[Evolution] Card create failed: #{e.message}"
      nil
    end

    def persist_message(workspace:, card:, contact:, evolution_id:, content:, attachment:,
                        from_me:, sender_name:, sender_phone:, quoted_id:)
      attachments = attachment ? [attachment] : []

      # Fallback de content para mídias sem legenda
      effective_content = content.presence ||
                          attachments.map { |a| a[:filename] }.compact.first ||
                          "[mídia]"

      meta = {}
      if quoted_id.present?
        original = Message.find_by(workspace: workspace, source_id: quoted_id)
        meta["in_reply_to"] = quoted_id
        if original
          meta["in_reply_to_content"] = {
            id:          quoted_id,
            content:     original.content,
            sender_name: original.sender_name,
            attachments: original.attachments
          }
        end
      end

      msg = Message.create!(
        workspace:    workspace,
        card:         card,
        contact:      contact,
        source_id:    evolution_id,
        content:      effective_content,
        message_type: from_me ? "outgoing" : "incoming",
        channel:      "whatsapp",
        sender_name:  sender_name,
        sender_phone: sender_phone,
        attachments:  attachments.map(&:stringify_keys),
        metadata:     meta
      )

      if attachments.any?
        DownloadMediaJob.perform_later(msg.id)
      end

      msg
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[Evolution] Message create failed evolution_id=#{evolution_id}: #{e.message}"
      nil
    end

    def emit_card_event(workspace, card, message, from_me)
      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "whatsapp_message",
        payload:    {
          source_id:    message.source_id,
          message_type: message.message_type,
          content:      message.content,
          sender_name:  message.sender_name,
          attachments:  message.attachments,
          metadata:     message.metadata,
          message_id:   message.id
        }.compact
      )
    end

    def broadcast(card, message)
      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        {
          event:   "whatsapp_message_received",
          card_id: card.id,
          event_data: {
            source_id:    message.source_id,
            content:      message.content,
            message_type: message.message_type,
            sender_name:  message.sender_name,
            attachments:  message.attachments,
            metadata:     message.metadata,
            created_at:   message.created_at
          }
        }
      )
    end

    # ── Extraction helpers ────────────────────────────────────────────────────

    def extract_text(msg_data)
      msg = msg_data[:message] || {}

      text = msg[:conversation] || msg.dig(:extendedTextMessage, :text)
      return text if text.present?

      caption = msg.dig(:imageMessage, :caption) ||
                msg.dig(:videoMessage, :caption) ||
                msg.dig(:documentMessage, :caption)
      return caption if caption.present?

      if msg[:locationMessage]
        loc  = msg[:locationMessage]
        lat  = loc[:degreesLatitude]
        lng  = loc[:degreesLongitude]
        name = loc[:name]
        addr = loc[:address]
        parts = ["Localização"]
        parts << name if name.present?
        parts << addr if addr.present?
        parts << "#{lat}, #{lng}" if lat && lng
        return parts.join("\n")
      end

      if msg[:contactMessage]
        display = msg[:contactMessage][:displayName].to_s
        vcard   = msg[:contactMessage][:vcard].to_s
        phone   = vcard[/TEL[^:]*:([+\d\s-]+)/i, 1]&.strip
        parts   = ["Contato: #{display}"]
        parts  << "Tel: #{phone}" if phone.present?
        return parts.join("\n")
      end

      nil
    end

    def extract_quoted_id(msg_data)
      msg = msg_data[:message] || {}
      context = msg.dig(:extendedTextMessage, :contextInfo) ||
                msg.dig(:imageMessage, :contextInfo) ||
                msg.dig(:videoMessage, :contextInfo) ||
                msg.dig(:audioMessage, :contextInfo) ||
                msg.dig(:documentMessage, :contextInfo) ||
                msg.dig(:stickerMessage, :contextInfo)
      context&.dig(:stanzaId)
    end

    def extract_attachment(msg_data)
      msg    = msg_data[:message] || {}
      b64    = msg_data.dig(:Message, :base64)

      if (im = msg[:imageMessage])
        { url: im[:url], content_type: im[:mimetype]&.split(";")&.first || "image/jpeg",
          filename: "image.jpg", base64: b64 }.compact
      elsif (am = msg[:audioMessage])
        ct = am[:mimetype]&.split(";")&.first || "audio/ogg"
        ext = ct.include?("mpeg") ? "mp3" : "ogg"
        { url: am[:url], content_type: ct, filename: "audio.#{ext}", base64: b64 }.compact
      elsif (dm = msg[:documentMessage])
        { url: dm[:url], content_type: dm[:mimetype] || "application/octet-stream",
          filename: dm[:fileName] || "document", base64: b64 }.compact
      elsif (vm = msg[:videoMessage])
        { url: vm[:url], content_type: vm[:mimetype]&.split(";")&.first || "video/mp4",
          filename: "video.mp4", base64: b64 }.compact
      elsif (sm = msg[:stickerMessage])
        { url: sm[:url], content_type: sm[:mimetype]&.split(";")&.first || "image/webp",
          filename: "sticker.webp", base64: b64 }.compact
      end
    end
  end
end
