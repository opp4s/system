module WhatsappLite
  module Api
    class SettingsController < BaseController
      def show
        settings = current_account.settings.dig('whatsapp_lite') || {}
        render json: {
          configured:       settings['evolution_api_url'].present? &&
                            settings['evolution_api_key'].present? &&
                            settings['evolution_webhook_token'].present?,
          evolution_api_url: settings['evolution_api_url'].to_s
        }
      end

      def update
        api_url       = params[:evolution_api_url].to_s.strip
        api_key       = params[:evolution_api_key].to_s.strip
        webhook_token = params[:evolution_webhook_token].to_s.strip

        missing = []
        missing << 'URL da Evolution API' if api_url.blank?
        missing << 'Chave da Evolution API' if api_key.blank?
        missing << 'Token de webhook' if webhook_token.blank?

        if missing.any?
          return render json: { error: "Campos obrigatórios: #{missing.join(', ')}" },
                        status: :unprocessable_entity
        end

        # Validate reachability (fast timeout, non-fatal)
        begin
          resp = Faraday.new(url: api_url) do |f|
            f.options.timeout      = 5
            f.options.open_timeout = 3
          end.get('/') do |req|
            req.headers['apikey'] = api_key
          end
          unless resp.status < 500
            return render json: { error: "Evolution respondeu #{resp.status}. Verifique a URL e a chave." },
                          status: :unprocessable_entity
          end
        rescue Faraday::Error => e
          return render json: { error: "Não foi possível conectar à Evolution: #{e.message}" },
                        status: :unprocessable_entity
        end

        current_settings = current_account.settings || {}
        current_settings['whatsapp_lite'] = {
          'evolution_api_url'       => api_url,
          'evolution_api_key'       => api_key,
          'evolution_webhook_token' => webhook_token
        }
        current_account.update!(settings: current_settings)

        render json: { configured: true }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
