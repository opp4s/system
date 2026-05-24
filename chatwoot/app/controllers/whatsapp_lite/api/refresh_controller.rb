module WhatsappLite
  module Api
    class RefreshController < BaseController
      def create
        render json: { stub: true, action: 'refresh' }
      end
    end
  end
end
