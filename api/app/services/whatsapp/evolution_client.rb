module Whatsapp
  class EvolutionClient
    BASE_URL    = ENV.fetch("EVOLUTION_URL", "https://evolution.opp4s.com")
    API_KEY     = ENV.fetch("EVOLUTION_API_KEY", "")
    ZAVY_WEBHOOK = ENV.fetch("APP_URL", "https://api.zavycrm.com")

    class ApiError < StandardError
      attr_reader :status
      def initialize(msg, status: nil)
        super(msg)
        @status = status
      end
    end

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |f|
        f.request  :json
        f.response :json
        f.adapter  Faraday.default_adapter
        f.headers["apikey"] = API_KEY
      end
    end

    # Cria instância e retorna { instance_id:, qr_base64:, expires_at: }
    def create_instance(instance_name, workspace_id:)
      body = {
        instanceName:  instance_name,
        integration:   "WHATSAPP-BAILEYS",
        qrcode:        true,
        webhook: {
          url:      "#{ZAVY_WEBHOOK}/api/v1/webhooks/evolution",
          byEvents: true,
          base64:   false,
          events:   ["CONNECTION_UPDATE", "QRCODE_UPDATED"]
        },
        webhookByEvents: true,
        chatwootAccountId: ENV["CHATWOOT_ACCOUNT_ID"].to_s.presence || "1",
        chatwootToken:     ENV["CHATWOOT_API_TOKEN"],
        chatwootUrl:       ENV["CHATWOOT_URL"],
        chatwootSignMsg:   false,
        chatwootReopenConversation: true,
        chatwootConversationPending: false
      }

      resp = post("/instance/create", body)

      qr_data = resp.dig("qrcode", "base64") || resp.dig("hash", "qrcode")

      {
        instance_id: resp.dig("instance", "instanceName") || instance_name,
        qr_base64:   qr_data,
        expires_at:  (Time.current + 60.seconds).iso8601
      }
    end

    # Obtém QR code de instância existente (quando expirou)
    def get_qr(instance_name)
      resp = get("/instance/connect/#{instance_name}")
      qr   = resp["base64"] || resp.dig("qrcode", "base64")
      { qr_base64: qr, expires_at: (Time.current + 60.seconds).iso8601 }
    end

    # Verifica estado da conexão
    def connection_state(instance_name)
      resp = get("/instance/connectionState/#{instance_name}")
      resp["instance"]&.dig("state") || resp["state"]
    rescue ApiError
      "not_found"
    end

    # Deleta instância
    def delete_instance(instance_name)
      resp = delete("/instance/delete/#{instance_name}")
      resp["status"] == "SUCCESS" || resp["deleted"]
    rescue ApiError
      false
    end

    # Lista instâncias
    def fetch_instances
      get("/instance/fetchInstances")
    end

    private

    def get(path)
      resp = @conn.get(path)
      handle_response(resp)
    end

    def post(path, body)
      resp = @conn.post(path, body)
      handle_response(resp)
    end

    def delete(path)
      resp = @conn.delete(path)
      handle_response(resp)
    end

    def handle_response(resp)
      return resp.body if resp.success?
      msg = resp.body.is_a?(Hash) ? (resp.body["message"] || resp.body.to_s) : resp.body.to_s
      raise ApiError.new(msg, status: resp.status)
    end
  end
end
