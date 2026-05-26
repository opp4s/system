module WhatsappLite
  module Api
    class WebhookController < ::ApplicationController
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_webhook!

      # Replay protection: rejeita requests com timestamp > 5 minutos
      REPLAY_WINDOW = 5.minutes

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
        # Ler body uma vez (necessário para HMAC e para o create)
        @raw_body = request.body.read
        request.body.rewind

        parts      = params[:instance_id].to_s.split('-')
        account_id = parts[1]&.to_i

        account = Account.find_by(id: account_id)
        creds   = WhatsappLite::AccountHelpers.credentials_for(account)
        token   = creds['evolution_webhook_token']

        return head(:unauthorized) unless account && token.present?

        # Tentar HMAC primeiro (mais seguro). Se headers não presentes, fallback para token estático.
        signature = request.headers['X-Webhook-Signature'].to_s
        timestamp = request.headers['X-Webhook-Timestamp'].to_s

        if signature.present? && timestamp.present?
          # HMAC mode: verifica assinatura + replay protection
          authenticate_hmac!(token, signature, timestamp)
        else
          # Fallback: token estático (compatibilidade com Evolution sem HMAC configurado)
          provided = request.headers['X-Evolution-Token'].to_s
          unless ActiveSupport::SecurityUtils.secure_compare(token, provided)
            return head(:unauthorized)
          end
        end

        Current.account = account
        @webhook_account = account
      end

      def authenticate_hmac!(secret, signature, timestamp)
        # Replay protection: timestamp não pode ser mais velho que REPLAY_WINDOW
        request_time = Time.at(timestamp.to_i) rescue nil
        if request_time.nil? || request_time < REPLAY_WINDOW.ago
          Rails.logger.tagged('whatsapp_lite', 'webhook', 'hmac') do
            Rails.logger.warn "replay rejected: timestamp=#{timestamp} age=#{request_time ? (Time.current - request_time).to_i : 'invalid'}s"
          end
          return head(:unauthorized)
        end

        # HMAC-SHA256: sign(secret, timestamp + body)
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

        # Não sobrescreve user_disconnected ou deleted — webhook só atua em estados automáticos
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

        # Skip non-message event types (delivery acks, reactions, etc.)
        msg_type = msg_data[:messageType].to_s
        return if msg_type.present? && !%w[conversation extendedTextMessage imageMessage audioMessage documentMessage].include?(msg_type)

        # Idempotência via source_id (key.id da Evolution).
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

        text_content = msg_data.dig(:message, :conversation) ||
                       msg_data.dig(:message, :extendedTextMessage, :text)

        media_url  = msg_data.dig(:message, :imageMessage, :url) ||
                     msg_data.dig(:message, :audioMessage, :url) ||
                     msg_data.dig(:message, :documentMessage, :url)
        media_type = if    msg_data.dig(:message, :imageMessage)    then 'image'
                     elsif msg_data.dig(:message, :audioMessage)    then 'audio'
                     elsif msg_data.dig(:message, :documentMessage) then 'document'
                     end

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
          Rails.logger.info "registered message_id=#{message.id} source_id=#{evolution_id} type=#{message.message_type} from_me=#{from_me} instance=#{channel.instance_id}"
        end

        if media_url
          WhatsappLite::DownloadMediaJob.perform_later(
            message.id, media_url, media_type, channel.instance_id
          )
        end
      end
    end
  end
end
