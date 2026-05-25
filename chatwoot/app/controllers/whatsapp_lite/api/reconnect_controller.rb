module WhatsappLite
  module Api
    class ReconnectController < BaseController
      def create
        channel = WhatsappLiteChannel.find_by!(
          instance_id: params[:instance_id],
          account:     current_account
        )

        return render json: { error: 'cannot_reconnect_deleted' }, status: :unprocessable_entity if channel.deleted?

        channel.lock!

        creds         = WhatsappLite::AccountHelpers.credentials_for(current_account)
        api_url       = creds['evolution_api_url']
        api_key       = creds['evolution_api_key']
        webhook_token = creds['evolution_webhook_token']

        if api_url.blank? || api_key.blank? || webhook_token.blank?
          if WhatsappLite::AccountHelpers.primary?(current_account)
            missing = []
            missing << 'URL da Evolution API' if api_url.blank?
            missing << 'Chave da Evolution API' if api_key.blank?
            missing << 'Token de webhook' if webhook_token.blank?
            raise WhatsappLite::EvolutionApiError,
                  "Configure as credenciais da Evolution API nas configurações. Faltando: #{missing.join(', ')}"
          else
            raise WhatsappLite::EvolutionApiError,
                  "Plugin não configurado. Contate o administrador da plataforma."
          end
        end

        conn = Faraday.new(url: api_url) do |f|
          f.options.timeout = 15
        end

        # Verifica se a instância ainda existe na Evolution; se não, recria
        begin
          resp = conn.get("/instance/connectionState/#{channel.instance_id}") do |req|
            req.headers['apikey'] = api_key
          end
          state = JSON.parse(resp.body, symbolize_names: true).dig(:instance, :state) rescue nil
          instance_exists = resp.status < 400
        rescue Faraday::Error
          instance_exists = false
        end

        unless instance_exists
          conn.post('/instance/create') do |req|
            req.headers['apikey']       = api_key
            req.headers['Content-Type'] = 'application/json'
            req.body = {
              instanceName: channel.instance_id,
              number:       channel.phone_number.gsub(/\D/, ''),
              qrcode:       true,
              integration:  'WHATSAPP-BAILEYS'
            }.to_json
          end rescue nil

          if webhook_token.present?
            webhook_url = "#{request.base_url}/api/v1/accounts/#{current_account.id}/whatsapp_lite/webhook/#{channel.instance_id}"
            conn.post("/webhook/set/#{channel.instance_id}") do |req|
              req.headers['apikey']       = api_key
              req.headers['Content-Type'] = 'application/json'
              req.body = {
                webhook: {
                  enabled:           true,
                  url:               webhook_url,
                  webhook_by_events: false,
                  webhook_base64:    false,
                  events:            %w[CONNECTION_UPDATE MESSAGES_UPSERT],
                  headers:           { 'X-Evolution-Token' => webhook_token }
                }
              }.to_json
            end rescue nil
          end
        end

        resp = conn.get("/instance/connect/#{channel.instance_id}") do |req|
          req.headers['apikey'] = api_key
        end
        data = JSON.parse(resp.body, symbolize_names: true)
        qr = data[:base64] || data.dig(:qrcode, :base64) || ''

        expires_at = (Time.current + 45.seconds).iso8601
        channel.update!(status: :qr_pending, qr_expires_at: Time.zone.parse(expires_at))

        render json: {
          instance_id:    channel.instance_id,
          qr_code_base64: qr,
          expires_at:     expires_at
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'not_found' }, status: :not_found
      rescue WhatsappLite::EvolutionApiError => e
        render json: { error: 'evolution_unavailable', message: e.message }, status: :service_unavailable
      rescue Faraday::Error => e
        render json: { error: 'evolution_unavailable', message: e.message }, status: :service_unavailable
      end
    end
  end
end
