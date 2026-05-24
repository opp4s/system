module WhatsappLite
  module Listeners
    class MessageListener
      include Singleton

      def message_created(event)
        message = event.data[:message]
        return unless message

        Rails.logger.tagged('whatsapp_lite', 'listener') do
          Rails.logger.info "received MESSAGE_CREATED message_id=#{message.id} type=#{message.message_type} inbox=#{message.inbox_id}"
        end

        return unless WhatsappLiteChannel.exists?(inbox_id: message.inbox_id)
        return unless message.outgoing?
        return if message.private?
        return if message.activity?

        WhatsappLite::SendMessageJob.perform_later(message.id)

        Rails.logger.tagged('whatsapp_lite', 'listener') do
          Rails.logger.info "enqueued SendMessageJob for message_id=#{message.id}"
        end
      end
    end
  end
end
