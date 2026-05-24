module WhatsappLite
  module Api
    class WebhookController < ::ApplicationController
      skip_before_action :verify_authenticity_token, raise: false

      def create
        render json: { stub: true, action: 'webhook' }
      end
    end
  end
end
