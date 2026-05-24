module WhatsappLite
  module Api
    class InstancesController < BaseController
      def index
        channels = WhatsappLiteChannel.where(account: current_account)
        render json: channels.map { |c|
          { instance_id: c.instance_id, phone_number: c.phone_number,
            status: c.status, inbox_id: c.inbox_id }
        }
      end

      def destroy
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        settings = current_account.settings.dig('whatsapp_lite') || {}
        api_url  = settings['evolution_api_url'] || ENV['EVOLUTION_API_URL']
        api_key  = settings['evolution_api_key']  || ENV['EVOLUTION_API_KEY']

        if api_url && api_key
          conn = Faraday.new(url: api_url)
          conn.delete("/instance/delete/#{channel.instance_id}") do |req|
            req.headers['apikey'] = api_key
          end rescue nil
        end

        if params[:destroy_inbox] == 'true'
          channel.inbox&.destroy
          channel.destroy
        else
          channel.update!(status: :disconnected)
        end

        render json: { success: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      end
    end
  end
end
