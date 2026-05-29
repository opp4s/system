module Whatsapp
  class EvolutionClient
    BASE_URL     = ENV.fetch("EVOLUTION_URL", "https://evolution.opp4s.com")
    API_KEY      = ENV.fetch("EVOLUTION_API_KEY", "")
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
        browserName:   "#{Date.today.strftime("%Y-%m-%d")} ZavyCRM",
        integration:   "WHATSAPP-BAILEYS",
        qrcode:        true,
        webhook: {
          url:      "#{ZAVY_WEBHOOK}/api/v1/webhooks/evolution",
          byEvents: false,
          base64:   true,
          events:   ["connection.update", "qrcode.updated"]
        },
        webhookByEvents: false,
        chatwootAccountId: ENV["CHATWOOT_ACCOUNT_ID"].to_s.presence || "1",
        chatwootToken:     ENV["CHATWOOT_API_TOKEN"],
        chatwootUrl:       ENV["CHATWOOT_URL"],
        chatwootSignMsg:   false,
        chatwootReopenConversation: true,
        chatwootConversationPending: false
      }

      resp = post("/instance/create", body)
      h = resp.is_a?(Hash) ? resp : {}

      # Evolution pode retornar qrcode como Hash {base64:...} ou String diretamente
      qrcode_val = h["qrcode"]
      qr_data = case qrcode_val
                when Hash   then qrcode_val["base64"]
                when String then qrcode_val
                end
      qr_data ||= (h.dig("hash", "qrcode") rescue nil)

      instance_val = h["instance"]
      resolved_id  = instance_val.is_a?(Hash) ? instance_val["instanceName"] : nil

      {
        instance_id: resolved_id || instance_name,
        qr_base64:   qr_data,
        expires_at:  (Time.current + 60.seconds).iso8601
      }
    end

    # Obtém QR code de instância existente (quando expirou)
    def get_qr(instance_name)
      resp = get("/instance/connect/#{instance_name}")
      h    = resp.is_a?(Hash) ? resp : {}
      qrcode_val = h["qrcode"]
      qr = case qrcode_val
           when Hash   then qrcode_val["base64"]
           when String then qrcode_val
           end
      qr ||= h["base64"]
      { qr_base64: qr, expires_at: (Time.current + 60.seconds).iso8601 }
    end

    # Obtém código de pareamento para a instância
    def get_pairing_code(instance_name, phone_number)
      resp = get("/instance/connect/#{instance_name}?number=#{phone_number}")
      code = resp.is_a?(Hash) ? (resp["pairingCode"] || resp["code"]) : nil
      {
        instance_id:  instance_name,
        pairing_code: code,
        expires_at:   (Time.current + 60.seconds).iso8601
      }
    end

    # Verifica estado da conexão — retorna string de estado ou "not_found"
    def connection_state(instance_name)
      resp = get("/instance/connectionState/#{instance_name}")
      h    = resp.is_a?(Hash) ? resp : {}
      h["instance"]&.dig("state") || h["state"] || "not_found"
    rescue ApiError
      "not_found"
    end

    # Deleta instância permanentemente da Evolution
    def delete_instance(instance_name)
      delete("/instance/delete/#{instance_name}")
      true
    rescue ApiError => e
      return true if e.status == 404
      false
    end

    # Faz logout (desconecta WhatsApp mas mantém instância na Evolution)
    def logout_instance(instance_name)
      delete("/instance/logout/#{instance_name}")
      true
    rescue ApiError => e
      return true if e.status == 404
      false
    end

    # Lista todas as instâncias
    def fetch_instances
      resp = get("/instance/fetchInstances")
      resp.is_a?(Array) ? resp : []
    rescue ApiError
      []
    end

    private

    def get(path)
      handle_response(@conn.get(path))
    end

    def post(path, body)
      handle_response(@conn.post(path, body))
    end

    def delete(path)
      handle_response(@conn.delete(path))
    end

    def handle_response(resp)
      return resp.body if resp.success?
      msg = resp.body.is_a?(Hash) ? (resp.body["message"] || resp.body.to_s) : resp.body.to_s
      raise ApiError.new(msg, status: resp.status)
    end
  end
end
