module WhatsappLite
  class SendMessageJob < ApplicationJob
    queue_as :default

    def perform(message_id)
      Rails.logger.tagged('whatsapp_lite', 'send_stub') do
        Rails.logger.info "JOB ENFILEIRADO message_id=#{message_id} (stub — implementar na Parte 7)"
      end
    end
  end
end
