module WhatsappLite
  module Api
    class InstancesController < BaseController
      def index
        scope = WhatsappLiteChannel.joins(:inbox).where(account: current_account)
        scope = scope.visible unless params[:include_deleted] == 'true'

        render json: scope.map { |c|
          {
            instance_id:  c.instance_id,
            phone_number: c.phone_number,
            status:       c.status,
            inbox_id:     c.inbox_id,
            inbox_name:   c.inbox&.name,
            display:      c.display_status
          }
        }
      end

      def destroy
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        settings = current_account.settings.dig('whatsapp_lite') || {}
        api_url  = settings['evolution_api_url']
        api_key  = settings['evolution_api_key']

        if api_url && api_key
          Faraday.new(url: api_url).delete("/instance/delete/#{channel.instance_id}") do |req|
            req.headers['apikey'] = api_key
          end rescue nil
        end

        if params[:hard_delete] == 'true'
          channel.inbox&.destroy
          channel.destroy
          render json: { success: true, status: 'destroyed' }
        else
          channel.update!(status: :deleted, deleted_at: Time.current)
          render json: { success: true, status: channel.status }
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      end
    end
  end
end
