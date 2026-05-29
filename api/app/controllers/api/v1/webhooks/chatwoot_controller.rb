module Api
  module V1
    module Webhooks
      class ChatwootController < ActionController::API
        # Chatwoot envia webhooks sem autenticação JWT — usamos account_id para
        # identificar o workspace e validamos que o account está configurado.
        before_action :verify_payload

        # POST /api/v1/webhooks/chatwoot
        def receive
          processor = ::Chatwoot::WebhookProcessor.new(webhook_payload)
          processor.call

          head :ok
        rescue StandardError => e
          Rails.logger.error "[Chatwoot Webhook] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
          head :ok  # sempre 200 para o Chatwoot não retentar infinitamente
        end

        private

        def verify_payload
          unless webhook_payload.is_a?(Hash) && webhook_payload[:event].present?
            head :unprocessable_entity
          end
        end

        def webhook_payload
          @webhook_payload ||= request.request_parameters
        end
      end
    end
  end
end
