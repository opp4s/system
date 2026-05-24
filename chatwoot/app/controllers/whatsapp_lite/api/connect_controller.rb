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
                channel_api = Channel::Api.create!(account_id: current_account.id)
                inbox = Inbox.create!(
                  account_id: current_account.id,
                  name:       "WhatsApp #{phone_number}",
                  channel:    channel_api
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
        settings = current_account.settings.dig('whatsapp_lite') || {}
        api_url  = settings['evolution_api_url'] || ENV['EVOLUTION_API_URL']
        api_key  = settings['evolution_api_key']  || ENV['EVOLUTION_API_KEY']

        raise WhatsappLite::EvolutionApiError, 'Evolution API não configurada' unless api_url && api_key

        use_pairing = params[:method] == 'pairing'

        conn = Faraday.new(url: api_url) do |f|
          f.options.timeout = 15
        end

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
          { qr_code_base64: data[:base64], expires_at: (Time.current + 45.seconds).iso8601 }
        end
      rescue Faraday::Error => e
        raise WhatsappLite::EvolutionApiError, e.message
      end
    end
  end
end
