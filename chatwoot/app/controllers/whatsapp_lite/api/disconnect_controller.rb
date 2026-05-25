module WhatsappLite
  module Api
    class DisconnectController < BaseController
      def create
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        return render json: { error: 'already_deleted' }, status: :unprocessable_entity if channel.deleted?

        settings = current_account.settings.dig('whatsapp_lite') || {}
        api_url  = settings['evolution_api_url']
        api_key  = settings['evolution_api_key']

        if api_url && api_key
          Faraday.new(url: api_url).delete("/instance/logout/#{channel.instance_id}") do |req|
            req.headers['apikey'] = api_key
          end rescue nil
        end

        channel.update!(status: :user_disconnected)

        render json: { success: true, status: 'user_disconnected' }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      end
    end
  end
end
