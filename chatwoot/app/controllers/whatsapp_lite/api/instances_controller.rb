module WhatsappLite
  module Api
    class InstancesController < BaseController
      def index
        render json: []
      end

      def destroy
        render json: { stub: true, action: 'disconnect' }
      end
    end
  end
end
