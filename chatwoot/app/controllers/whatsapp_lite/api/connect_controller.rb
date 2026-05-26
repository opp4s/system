module WhatsappLite
  module Api
    class ConnectController < BaseController
      def create
        unless phone_number_valid?
          return render json: { error: 'invalid_phone' }, status: :unprocessable_entity
        end

        retries = 0
        begin
          channel = nil
          ActiveRecord::Base.transaction do
            channel = WhatsappLiteChannel.find_by(
              instance_id: instance_id,
              account:     current_account
            )

            if channel.nil?
              WhatsappLiteChannel.transaction(requires_new: true) do
                channel_wl = Channel::WhatsappLite.create!(account_id: current_account.id)
                inbox = Inbox.create!(
                  account_id: current_account.id,
                  name:       "WhatsApp #{phone_number}",
                  channel:    channel_wl
                )
                channel = WhatsappLiteChannel.create!(
                  instance_id:  instance_id,
                  account_id:   current_account.id,
                  phone_number: phone_number,
                  inbox:        inbox
                )
              end
            end

            channel.lock!

            evolution_data = call_evolution!(channel)
            channel.update!(
              status:        :qr_pending,
              qr_expires_at: Time.zone.parse(evolution_data[:expires_at])
            )

            render json: { instance_id: channel.instance_id, inbox_id: channel.inbox_id }
                           .merge(evolution_data)
          end
        rescue ActiveRecord::RecordNotUnique
          retries += 1
          raise if retries > 3
          sleep 0.05
          retry
        rescue WhatsappLite::EvolutionApiError => e
          render json: { error: 'evolution_unavailable', message: e.message }, status: :service_unavailable
        end
      end

      private

      def phone_number_valid?
        params[:phone_number].to_s.match?(/\A\+?\d{10,15}\z/)
      end

      def phone_number
        params[:phone_number]
      end

      def phone_sanitized
        phone_number.to_s.gsub(/\D/, '')
      end

      def instance_id
        "cw-#{current_account.id}-#{phone_sanitized}"
      end

      def call_evolution!(channel)
        creds         = WhatsappLite::AccountHelpers.credentials_for(current_account)
        api_url       = creds['evolution_api_url']       || ENV['EVOLUTION_API_URL']
        api_key       = creds['evolution_api_key']       || ENV['EVOLUTION_API_KEY']
        webhook_token = creds['evolution_webhook_token'] || ENV['EVOLUTION_WEBHOOK_TOKEN']

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

        use_pairing = params[:method] == 'pairing'

        conn = Faraday.new(url: api_url) do |f|
          f.options.timeout = 15
        end

        # Create or reconnect instance — ignore "already exists" errors
        begin
          conn.post('/instance/create') do |req|
            req.headers['apikey']       = api_key
            req.headers['Content-Type'] = 'application/json'
            req.body = {
              instanceName: channel.instance_id,
              number:       phone_sanitized,
              qrcode:       !use_pairing,
              integration:  'WHATSAPP-BAILEYS'
            }.to_json
          end
        rescue Faraday::Error
          # instance may already exist on Evolution — proceed to QR step
        end

        # Configure Evolution webhook so it sends events back to our controller
        if webhook_token.present?
          webhook_url = "#{request.base_url}/api/v1/accounts/#{current_account.id}/whatsapp_lite/webhook/#{channel.instance_id}"
          begin
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
            end
          rescue Faraday::Error => e
            Rails.logger.warn "[whatsapp_lite] webhook set failed for #{channel.instance_id}: #{e.message}"
          end
        end

        if use_pairing
          resp = conn.post("/instance/pairingCode/#{channel.instance_id}") do |req|
            req.headers['apikey']       = api_key
            req.headers['Content-Type'] = 'application/json'
            req.body = { number: phone_sanitized }.to_json
          end
          data = JSON.parse(resp.body, symbolize_names: true)
          { pairing_code: data[:code], expires_at: (Time.current + 90.seconds).iso8601 }
        else
          resp = conn.get("/instance/connect/#{channel.instance_id}") do |req|
            req.headers['apikey'] = api_key
          end
          data = JSON.parse(resp.body, symbolize_names: true)
          # Evolution v2: base64 already contains the full "data:image/png;base64,..." URI
          qr = data[:base64] || data.dig(:qrcode, :base64) || ''
          { qr_code_base64: qr, expires_at: (Time.current + 45.seconds).iso8601 }
        end
      rescue Faraday::Error => e
        raise WhatsappLite::EvolutionApiError, e.message
      end
    end
  end
end
