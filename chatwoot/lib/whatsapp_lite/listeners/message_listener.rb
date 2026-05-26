module WhatsappLite
  module Listeners
    class MessageListener
      include Singleton

      def message_created(event)
        message = event.data[:message]
        return unless message

        Rails.logger.tagged('whatsapp_lite', 'listener') do
          Rails.logger.info "received MESSAGE_CREATED message_id=#{message.id} type=#{message.message_type} inbox=#{message.inbox_id} source_id=#{message.source_id.inspect}"
        end

        return unless WhatsappLiteChannel.exists?(inbox_id: message.inbox_id)
        return unless message.outgoing?
        return if message.private?
        return if message.activity?

        # Mensagens criadas pelo webhook (celular físico, n8n, eco da Evolution)
        # já têm source_id setado. NÃO devem ser reenviadas — já existem na Evolution.
        # Apenas mensagens digitadas pelo agente no Chatwoot começam sem source_id
        # e precisam ser despachadas para a Evolution.
        if message.source_id.present?
          Rails.logger.tagged('whatsapp_lite', 'listener') do
            Rails.logger.info "skipping send: message_id=#{message.id} already has source_id=#{message.source_id} (originated from Evolution webhook)"
          end
          return
        end

        WhatsappLite::SendMessageJob.perform_later(message.id)

        Rails.logger.tagged('whatsapp_lite', 'listener') do
          Rails.logger.info "enqueued SendMessageJob for message_id=#{message.id}"
        end
      end
    end
  end
end
