module Chatwoot
  class WebhookProcessor
    def initialize(payload)
      @payload    = payload.deep_symbolize_keys
      @event_type = @payload[:event]
      @account_id = (@payload.dig(:account, :id) || @payload[:account_id]).to_s
    end

    def call
      workspace = find_workspace
      return false unless workspace

      case @event_type
      when "conversation_created"        then handle_conversation_created(workspace)
      when "conversation_status_changed" then handle_status_changed(workspace)
      when "message_created"             then handle_message_created(workspace)
      end

      true
    end

    private

    # Bug fix: múltiplos workspaces compartilham o mesmo chatwoot_account_id.
    # Usar inbox_id do payload → WhatsappInstance → workspace correto.
    def find_workspace
      inbox_id = extract_inbox_id_from_payload
      if inbox_id > 0
        wi = WhatsappInstance.find_by(chatwoot_inbox_id: inbox_id)
        return wi.workspace if wi
      end

      # Fallback: primeiro workspace com este account_id
      config = ChatwootConfig.find_by(chatwoot_account_id: @account_id)
      config&.workspace
    end

    def extract_inbox_id_from_payload
      (@payload[:inbox_id] ||
       @payload.dig(:conversation, :inbox_id) ||
       @payload.dig(:inbox, :id)).to_i
    end

    # ── Handlers ──────────────────────────────────────────────────────────────

    def handle_conversation_created(workspace)
      conv_data = @payload
      conv_id   = (conv_data[:id] || conv_data.dig(:conversation, :id)).to_i
      return unless conv_id > 0

      conv = Conversation.find_or_initialize_by(
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )

      conv.assign_attributes(
        chatwoot_account_id: @account_id,
        inbox_id:            extract_inbox_id_from_payload,
        contact_id:          extract_contact_id(conv_data),
        status:              normalize_status(conv_data[:status] || conv_data.dig(:conversation, :status)),
        last_activity_at:    Time.current,
        meta:                build_meta(conv_data)
      )
      conv.save!

      try_auto_link(workspace, conv) unless conv.linked?
    end

    def handle_status_changed(workspace)
      conv_id = @payload[:id].to_i
      return unless conv_id > 0

      conv = Conversation.find_by(
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )
      return unless conv

      new_status = normalize_status(@payload[:status])
      conv.update!(status: new_status, last_activity_at: Time.current)

      if conv.linked?
        card_event = CardEvent.create!(
          card:       conv.card,
          workspace:  workspace,
          event_type: "chatwoot_message",
          payload:    {
            subtype:         "status_changed",
            status:          new_status,
            conversation_id: conv_id
          }
        )
        broadcast(conv.card, "chatwoot_status_changed",
                  event_data: {
                    id:         card_event.id,
                    event_type: card_event.event_type,
                    payload:    card_event.payload,
                    created_at: card_event.created_at
                  })
      end
    end

    def handle_message_created(workspace)
      msg          = @payload
      conv_id      = (msg.dig(:conversation, :id) || msg[:conversation_id]).to_i
      message_type = msg[:message_type].to_s
      content      = msg[:content].to_s
      has_attachment = msg[:attachments].present? && msg[:attachments].any?
      return if (content.blank? && !has_attachment) || conv_id == 0

      conv = Conversation.find_or_initialize_by(
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )

      unless conv.persisted?
        conv.assign_attributes(
          chatwoot_account_id: @account_id,
          inbox_id:            extract_inbox_id_from_payload,
          contact_id:          extract_contact_id(msg),
          status:              "open",
          last_activity_at:    Time.current
        )
        conv.save!
        # conversation_created pode ter sido perdido — tentar auto-link aqui também
        try_auto_link(workspace, conv) unless conv.linked?
      else
        conv.update!(last_activity_at: Time.current)
        # Tentar linkar se ainda não está (conversation_created pode ter falhado antes)
        try_auto_link(workspace, conv) unless conv.linked?
      end

      return unless conv.linked?

      sender_name  = msg.dig(:sender, :name).to_s
      sender_phone = msg.dig(:sender, :phone_number).to_s.presence
      chatwoot_msg_id = msg[:id].to_s
      source_id    = msg[:source_id].to_s.presence
      in_reply_to  = msg.dig(:content_attributes, :in_reply_to)

      # Extrair attachments do webhook (imagens, documentos, áudios)
      cw_attachments = (msg[:attachments] || []).map do |att|
        {
          url:          att[:data_url] || att[:file_url],
          content_type: att[:file_type],
          filename:     att[:file_name] || att[:file_type]
        }.compact
      end

      persist_message(
        workspace:           workspace,
        conv:                conv,
        chatwoot_message_id: chatwoot_msg_id,
        content:             content,
        message_type:        message_type == "outgoing" ? "outgoing" : "incoming",
        sender_name:         sender_name,
        sender_phone:        sender_phone,
        attachments:         cw_attachments,
        in_reply_to:         in_reply_to,
        source_id:           source_id
      )

      card_event = CardEvent.create!(
        card:       conv.card,
        workspace:  workspace,
        event_type: "chatwoot_message",
        payload:    {
          subtype:         "message",
          message_type:    message_type,
          content:         content,
          sender_name:     sender_name,
          conversation_id: conv_id,
          message_id:      msg[:id],
          attachments:     cw_attachments,
          in_reply_to:     in_reply_to
        }.compact
      )

      broadcast(conv.card, "chatwoot_message_received",
                event_data: {
                  id:         card_event.id,
                  event_type: card_event.event_type,
                  payload:    card_event.payload,
                  created_at: card_event.created_at
                })
    end

    # ── Auto-link ─────────────────────────────────────────────────────────────

    def try_auto_link(workspace, conv)
      return if conv.contact_id.blank?

      contact = Contact.find_by(workspace: workspace, chatwoot_contact_id: conv.contact_id)

      # Bug fix: Contact pode não existir ainda para novos remetentes.
      # Buscar por phone ou criar a partir dos dados do payload.
      unless contact
        sender_phone = @payload.dig(:meta, :sender, :phone_number).to_s.presence ||
                       @payload.dig(:sender, :phone_number).to_s.presence
        sender_name  = @payload.dig(:meta, :sender, :name).to_s.presence ||
                       @payload.dig(:sender, :name).to_s.presence

        if sender_phone.present?
          contact = Contact.find_by(workspace: workspace, phone_number: sender_phone)
        end

        unless contact
          contact = Contact.find_or_create_by!(
            workspace:           workspace,
            chatwoot_contact_id: conv.contact_id
          ) do |c|
            c.name         = sender_name || sender_phone || "Contato #{conv.contact_id}"
            c.phone_number = sender_phone
          end
        else
          contact.update_columns(chatwoot_contact_id: conv.contact_id) if contact.chatwoot_contact_id.blank?
        end
      end

      return unless contact

      card = nil
      if contact.phone_number.present?
        card = workspace.cards.active
                        .where(contact_phone: contact.phone_number)
                        .order(created_at: :desc)
                        .first
      end

      if card
        link_conv_to_card(conv, card, workspace)
        return
      end

      auto_create_card(workspace, conv, contact)
    end

    def auto_create_card(workspace, conv, contact)
      config = workspace.chatwoot_config

      # Prioridade 1: pipeline vinculado à instância WhatsApp do inbox da conversa
      pipeline, stage = pipeline_from_whatsapp_instance(workspace, conv)

      # Prioridade 2: configuração global auto_create_card
      unless pipeline
        return unless config&.settings&.dig("auto_create_card")
        pipeline_id = config.settings["auto_create_pipeline_id"].to_i
        stage_id    = config.settings["auto_create_stage_id"].to_i
        return unless pipeline_id > 0 && stage_id > 0
        pipeline = workspace.pipelines.find_by(id: pipeline_id)
        stage    = pipeline&.stages&.find_by(id: stage_id)
      end

      return unless pipeline && stage

      card = workspace.cards.create!(
        pipeline:         pipeline,
        stage:            stage,
        title:            contact.name,
        contact_name:     contact.name,
        contact_phone:    contact.phone_number,
        contact_email:    contact.email,
        stage_changed_at: Time.current
      )

      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "card_created",
        payload:    {
          title:        card.title,
          stage_id:     stage.id,
          auto_created: true,
          source:       "chatwoot_webhook"
        }
      )

      link_conv_to_card(conv, card, workspace)

      ActionCable.server.broadcast(
        "pipeline_#{pipeline.id}",
        { event: "card_created", card_id: card.id, title: card.title }
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[WebhookProcessor] auto_create_card failed: #{e.message}"
    end

    def link_conv_to_card(conv, card, workspace)
      conv.update!(card: card)

      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "conversation_linked",
        payload:    { chatwoot_conversation_id: conv.chatwoot_conversation_id }
      )

      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        { event: "conversation_linked", card_id: card.id,
          chatwoot_conversation_id: conv.chatwoot_conversation_id }
      )
    end

    # ── Helpers ───────────────────────────────────────────────────────────────

    # Retorna [pipeline, stage] a partir do inbox_id da conversa → WhatsappInstance → pipeline_id
    def pipeline_from_whatsapp_instance(workspace, conv)
      inbox_id = conv.inbox_id
      return [nil, nil] unless inbox_id.present?

      wi = WhatsappInstance.find_by(workspace: workspace, chatwoot_inbox_id: inbox_id)
      return [nil, nil] unless wi&.pipeline_id?

      pipeline = wi.pipeline
      return [nil, nil] unless pipeline

      stage = pipeline.stages.where(stage_type: "intermediate").order(:position).first ||
              pipeline.stages.order(:position).first
      [pipeline, stage]
    rescue => e
      Rails.logger.warn "[WebhookProcessor] pipeline_from_whatsapp_instance error: #{e.message}"
      [nil, nil]
    end

    def persist_message(workspace:, conv:, chatwoot_message_id:, content:, message_type:,
                        sender_name:, sender_phone:, attachments: [], in_reply_to: nil, source_id: nil)
      return if chatwoot_message_id.blank?

      meta = {}
      meta["in_reply_to"] = in_reply_to if in_reply_to.present?

      msg_record = Message.find_or_initialize_by(
        workspace:           workspace,
        chatwoot_message_id: chatwoot_message_id
      )
      # Áudio/mídia pode ter content vazio — usar filename como fallback
      effective_content = content.presence ||
                          attachments.map { |a| a["filename"] }.compact.first ||
                          "[mídia]"

      msg_record.assign_attributes(
        card:         conv.card,
        conversation: conv,
        content:      effective_content,
        message_type: message_type,
        sender_name:  sender_name,
        sender_phone: sender_phone,
        channel:      "whatsapp",
        attachments:  attachments,
        source_id:    source_id,
        metadata:     (msg_record.metadata || {}).merge(meta)
      )
      if sender_phone.present? && msg_record.contact_id.blank?
        msg_record.contact = Contact.find_by(workspace: workspace, phone_number: sender_phone)
      end
      msg_record.save!

      # Enfileirar transcrição se tiver attachment de áudio
      has_audio = attachments.any? { |a| a["content_type"].to_s.start_with?("audio/") }
      TranscribeAudioJob.perform_later(msg_record.id) if has_audio && msg_record.persisted?
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[WebhookProcessor] persist_message failed: #{e.message}"
    end

    def extract_contact_id(data)
      (
        data.dig(:meta, :sender, :id) ||
        data.dig(:contact_inbox, :contact, :id) ||
        data[:contact_id]
      ).to_i.then { |v| v > 0 ? v : nil }
    end

    def normalize_status(raw)
      s = raw.to_s.downcase
      Conversation::STATUSES.include?(s) ? s : "open"
    end

    def build_meta(data)
      {
        inbox_id:    extract_inbox_id_from_payload,
        sender_name: data.dig(:meta, :sender, :name) ||
                     data.dig(:contact_inbox, :contact, :name)
      }.compact
    end

    def broadcast(card, event_type, extra = {})
      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        { event: event_type, card_id: card.id }.merge(extra)
      )
    end
  end
end
