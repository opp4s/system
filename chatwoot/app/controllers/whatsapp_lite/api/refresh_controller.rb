module WhatsappLite
  module Api
    class RefreshController < BaseController
      def create
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        creds    = WhatsappLite::AccountHelpers.credentials_for(current_account)
        api_url  = creds['evolution_api_url'] || ENV['EVOLUTION_API_URL']
        api_key  = creds['evolution_api_key'] || ENV['EVOLUTION_API_KEY']

        conn = Faraday.new(url: api_url) do |f|
          f.options.timeout = 15
        end
        resp = conn.get("/instance/connect/#{channel.instance_id}") do |req|
          req.headers['apikey'] = api_key
        end
        data = JSON.parse(resp.body, symbolize_names: true)

        expires_at = (Time.current + 45.seconds).iso8601
        channel.update!(qr_expires_at: Time.zone.parse(expires_at))

        render json: { qr_code_base64: data[:base64], expires_at: expires_at }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      rescue Faraday::Error => e
        render json: { error: 'evolution_unavailable', message: e.message }, status: :service_unavailable
      end
    end
  end
end
