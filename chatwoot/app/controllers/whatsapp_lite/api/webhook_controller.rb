module WhatsappLite
  module Api
    class WebhookController < ::ApplicationController
      skip_before_action :verify_authenticity_token, raise: false
      before_action :authenticate_webhook!

      def create
        payload = JSON.parse(request.body.read, symbolize_names: true)

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
        parts      = params[:instance_id].to_s.split('-')
        account_id = parts[1]&.to_i

        account  = Account.find_by(id: account_id)
        token    = account&.settings&.dig('whatsapp_lite', 'evolution_webhook_token')
        provided = request.headers['X-Evolution-Token'].to_s

        unless account && token.present? &&
               ActiveSupport::SecurityUtils.secure_compare(token, provided)
          return head :unauthorized
        end

        Current.account = account
        @webhook_account = account
      end

      def handle_connection_update(payload)
        channel = WhatsappLiteChannel.find_by(instance_id: params[:instance_id])
        return unless channel

        new_status = case payload.dig(:data, :state)
                     when 'open'             then :connected
                     when 'close', 'refused' then :disconnected
                     end

        channel.update!(status: new_status) if new_status
      end

      def handle_message_upsert(payload)
        channel = WhatsappLiteChannel.find_by(instance_id: params[:instance_id])
        return unless channel

        msg_data = Array(payload.dig(:data, :messages)).first || payload[:data]
        return if msg_data.blank?
        return if msg_data.dig(:key, :fromMe)

        sender_jid    = msg_data.dig(:key, :remoteJid).to_s
        sender_digits = sender_jid.split('@').first.gsub(/\D/, '')
        sender_phone  = "+#{sender_digits}"
        sender_name   = msg_data[:pushName] || sender_phone

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
          phone_number: sender_phone
        ) do |c|
          c.name = sender_name
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
          message_type: :incoming,
          content:      text_content.presence || '',
          content_type: :text
        )

        if media_url
          WhatsappLite::DownloadMediaJob.perform_later(
            message.id, media_url, media_type, channel.instance_id
          )
        end
      end
    end
  end
end
