module WhatsappLite
  module Api
    class WebhookController < ::ApplicationController
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_webhook!

      # Replay protection: rejeita requests com timestamp > 5 minutos
      REPLAY_WINDOW = 5.minutes

      ALLOWED_MESSAGE_TYPES = %w[
        conversation extendedTextMessage
        imageMessage audioMessage documentMessage videoMessage stickerMessage
        contactMessage locationMessage
      ].freeze

      def create
        payload = JSON.parse(@raw_body, symbolize_names: true)

        case payload[:event]
        when 'connection.update'
          handle_connection_update(payload)
        when 'messages.upsert'
          handle_message_upsert(payload)
        end

        head :ok
      rescue JSON::ParserError
        head :bad_request
      end

      private

      def authenticate_webhook!
        @raw_body = request.body.read
        request.body.rewind

        parts      = params[:instance_id].to_s.split('-')
        account_id = parts[1]&.to_i

        account = Account.find_by(id: account_id)
        creds   = WhatsappLite::AccountHelpers.credentials_for(account)
        token   = creds['evolution_webhook_token']

        return head(:unauthorized) unless account && token.present?

        signature = request.headers['X-Webhook-Signature'].to_s
        timestamp = request.headers['X-Webhook-Timestamp'].to_s

        if signature.present? && timestamp.present?
          authenticate_hmac!(token, signature, timestamp)
        else
          provided = request.headers['X-Evolution-Token'].to_s
          unless ActiveSupport::SecurityUtils.secure_compare(token, provided)
            return head(:unauthorized)
          end
        end

        Current.account = account
        @webhook_account = account
      end

      def authenticate_hmac!(secret, signature, timestamp)
        request_time = Time.at(timestamp.to_i) rescue nil
        if request_time.nil? || request_time < REPLAY_WINDOW.ago
          Rails.logger.tagged('whatsapp_lite', 'webhook', 'hmac') do
            Rails.logger.warn "replay rejected: timestamp=#{timestamp}"
          end
          return head(:unauthorized)
        end

        expected = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}#{@raw_body}")

        unless ActiveSupport::SecurityUtils.secure_compare(expected, signature)
          Rails.logger.tagged('whatsapp_lite', 'webhook', 'hmac') do
            Rails.logger.warn "signature mismatch for instance=#{params[:instance_id]}"
          end
          return head(:unauthorized)
        end
      end

      def handle_connection_update(payload)
        channel = WhatsappLiteChannel.find_by(instance_id: params[:instance_id])
        return unless channel
        return if channel.user_disconnected? || channel.deleted?

        new_status = case payload.dig(:data, :state)
                     when 'open'             then :connected
                     when 'close', 'refused' then :auto_disconnected
                     end

        channel.update!(status: new_status) if new_status
      end

      def handle_message_upsert(payload)
        channel = WhatsappLiteChannel.find_by(instance_id: params[:instance_id])
        return unless channel

        msg_data = Array(payload.dig(:data, :messages)).first || payload[:data]
        return if msg_data.blank?

        msg_type = msg_data[:messageType].to_s
        return if msg_type.present? && !ALLOWED_MESSAGE_TYPES.include?(msg_type)

        evolution_id = msg_data.dig(:key, :id)
        return if evolution_id.blank?

        if Message.exists?(inbox_id: channel.inbox_id, source_id: evolution_id)
          Rails.logger.tagged('whatsapp_lite', 'webhook') do
            Rails.logger.info "duplicate skipped instance=#{channel.instance_id} source_id=#{evolution_id}"
          end
          return
        end

        from_me = msg_data.dig(:key, :fromMe) ? true : false

        sender_jid    = msg_data.dig(:key, :remoteJid).to_s
        sender_digits = sender_jid.split('@').first.gsub(/\D/, '')
        contact_phone = "+#{sender_digits}"
        contact_name  = msg_data[:pushName].presence || contact_phone

        # Extrair conteúdo de texto
        text_content = extract_text_content(msg_data)

        # Extrair mídia (url + tipo)
        media_url, media_type = extract_media(msg_data)

        contact = Contact.find_or_create_by!(
          account_id:   channel.inbox.account_id,
          phone_number: contact_phone
        ) do |c|
          c.name = contact_name
        end

        contact_inbox = ContactInbox.find_or_create_by!(
          contact: contact,
          inbox:   channel.inbox
        ) do |ci|
          ci.source_id = SecureRandom.uuid
        end

        conversation = Conversation
          .where(contact: contact, inbox: channel.inbox, status: %i[open pending])
          .where('last_activity_at > ?', 24.hours.ago)
          .first

        conversation ||= Conversation.create!(
          account_id:    channel.inbox.account_id,
          contact:       contact,
          inbox_id:      channel.inbox_id,
          contact_inbox: contact_inbox,
          status:        :open,
          additional_attributes: { source: 'whatsapp_lite' }
        )

        message = conversation.messages.create!(
          account_id:   channel.inbox.account_id,
          inbox_id:     channel.inbox_id,
          message_type: from_me ? :outgoing : :incoming,
          content:      text_content.presence || '',
          content_type: :text,
          source_id:    evolution_id
        )

        Rails.logger.tagged('whatsapp_lite', 'webhook') do
          Rails.logger.info "registered message_id=#{message.id} source_id=#{evolution_id} type=#{message.message_type} from_me=#{from_me} media=#{media_type || 'none'} instance=#{channel.instance_id}"
        end

        if media_url
          WhatsappLite::DownloadMediaJob.perform_later(
            message.id, media_url, media_type, channel.instance_id
          )
        end
      end

      # --- Content extraction helpers ---

      def extract_text_content(msg_data)
        msg = msg_data[:message] || {}

        # Texto simples ou extendido
        text = msg.dig(:conversation) || msg.dig(:extendedTextMessage, :text)
        return text if text.present?

        # Caption de mídia (imagem, vídeo, documento)
        caption = msg.dig(:imageMessage, :caption) ||
                  msg.dig(:videoMessage, :caption) ||
                  msg.dig(:documentMessage, :caption)
        return caption if caption.present?

        # Localização → texto formatado
        if msg[:locationMessage]
          loc = msg[:locationMessage]
          lat = loc[:degreesLatitude]
          lng = loc[:degreesLongitude]
          name = loc[:name]
          addr = loc[:address]
          parts = ["📍 Localização"]
          parts << name if name.present?
          parts << addr if addr.present?
          parts << "#{lat}, #{lng}" if lat && lng
          parts << "https://maps.google.com/maps?q=#{lat},#{lng}" if lat && lng
          return parts.join("\n")
        end

        # Contato (vCard) → texto formatado
        if msg[:contactMessage]
          vcard = msg[:contactMessage][:vcard].to_s
          display = msg[:contactMessage][:displayName].to_s
          # Extrair telefone do vCard
          phone = vcard[/TEL[^:]*:([+\d\s-]+)/i, 1]&.strip
          parts = ["👤 Contato: #{display}"]
          parts << "Tel: #{phone}" if phone.present?
          return parts.join("\n")
        end

        # Sticker → sem texto (só mídia)
        nil
      end

      def extract_media(msg_data)
        msg = msg_data[:message] || {}

        if msg[:imageMessage]
          [msg.dig(:imageMessage, :url), 'image']
        elsif msg[:audioMessage]
          [msg.dig(:audioMessage, :url), 'audio']
        elsif msg[:documentMessage]
          [msg.dig(:documentMessage, :url), 'document']
        elsif msg[:videoMessage]
          [msg.dig(:videoMessage, :url), 'video']
        elsif msg[:stickerMessage]
          [msg.dig(:stickerMessage, :url), 'sticker']
        else
          [nil, nil]
        end
      end
    end
  end
end
