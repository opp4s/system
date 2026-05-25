module WhatsappLite
  module Api
    class SettingsController < BaseController
      def show
        is_primary = WhatsappLite::AccountHelpers.primary?(current_account)
        creds      = WhatsappLite::AccountHelpers.credentials_for(current_account)

        configured = creds['evolution_api_url'].present? &&
                     creds['evolution_api_key'].present? &&
                     creds['evolution_webhook_token'].present?

        render json: {
          is_primary_account: is_primary,
          configured:         configured,
          evolution_api_url:  is_primary ? creds['evolution_api_url'].to_s : nil
        }
      end

      def update
        unless WhatsappLite::AccountHelpers.primary?(current_account)
          return render json: {
            error:   'forbidden',
            message: 'Apenas a conta principal pode configurar credenciais.'
          }, status: :forbidden
        end

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

        test_connection!(api_url, api_key)

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
      rescue Faraday::Error, StandardError => e
        render json: {
          error:   'evolution_connection_failed',
          message: "Não foi possível conectar à Evolution: #{e.message}"
        }, status: :unprocessable_entity
      end

      private

      def test_connection!(url, key)
        resp = Faraday.new(url: url) do |f|
          f.options.timeout      = 5
          f.options.open_timeout = 3
        end.get('/') do |req|
          req.headers['apikey'] = key
        end
        if resp.status >= 500
          raise StandardError, "Evolution respondeu #{resp.status}. Verifique a URL e a chave."
        end
      end
    end
  end
end
