module WhatsappLite
  module Api
    class ConnectController < BaseController
      def create
        render json: { stub: true, action: 'connect', account_id: params[:account_id] }
      end
    end
  end
end
