module WhatsappLite
  module Api
    class StatusController < BaseController
      def show
        render json: { stub: true, action: 'status' }
      end
    end
  end
end
