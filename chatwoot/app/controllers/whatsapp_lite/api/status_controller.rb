module WhatsappLite
  module Api
    class StatusController < BaseController
      def show
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        status = if channel.qr_pending? &&
                    channel.qr_expires_at.present? &&
                    channel.qr_expires_at < Time.current
                   'qr_expired'
                 else
                   channel.status
                 end

        render json: { instance_id: channel.instance_id, status: status }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      end
    end
  end
end
