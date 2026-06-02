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
          enabled:  true,
          url:      "#{ZAVY_WEBHOOK}/api/v1/webhooks/evolution",
          byEvents: false,
          base64:   true,
          events:   WEBHOOK_EVENTS
        },
        webhookByEvents: false
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

    # Atualiza configuração do webhook de uma instância existente
    WEBHOOK_EVENTS = %w[CONNECTION_UPDATE QRCODE_UPDATED MESSAGES_UPSERT MESSAGES_UPDATE].freeze

    def update_webhook(instance_name)
      body = {
        webhook: {
          enabled:  true,
          url:      "#{ZAVY_WEBHOOK}/api/v1/webhooks/evolution",
          byEvents: false,
          base64:   true,
          events:   WEBHOOK_EVENTS
        }
      }
      post("/webhook/set/#{instance_name}", body)
      true
    rescue ApiError => e
      Rails.logger.warn "[Evolution] update_webhook failed #{instance_name}: #{e.message}"
      false
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

    # Lista todas as instâncias com status e ownerJid
    def fetch_instances
      resp = get("/instance/fetchInstances")
      resp.is_a?(Array) ? resp : []
    rescue ApiError
      []
    end

    # Retorna hash { instance_name => { status:, phone: } } para um conjunto de nomes
    # Substitui N chamadas a connection_state por 1 chamada a fetchInstances
    def bulk_status(instance_names)
      all = fetch_instances
      result = {}
      all.each do |ei|
        name = ei["name"]
        next unless instance_names.include?(name)
        raw_status  = ei["connectionStatus"]
        owner_jid   = ei["ownerJid"]
        phone       = owner_jid&.split("@")&.first&.then { |p| p.present? ? "+#{p}" : nil }
        result[name] = {
          status: map_evolution_status(raw_status),
          phone:  phone
        }
      end
      result
    rescue => e
      Rails.logger.warn "[Evolution] bulk_status error: #{e.message}"
      {}
    end

    # Pede à Evolution para re-fetchar a mídia e retornar como base64
    def get_base64_from_media(instance_name, message_id:, remote_jid:)
      body = { message: { key: { id: message_id, remoteJid: remote_jid } } }
      post("/chat/getBase64FromMediaMessage/#{instance_name}", body)
    rescue ApiError => e
      Rails.logger.warn "[Evolution] getBase64FromMediaMessage failed #{instance_name}: #{e.message}"
      nil
    end

    # ── Message send ──────────────────────────────────────────────────────────

    def send_text(instance_name, number, text, quoted_source_id: nil)
      body = { number: format_number(number), text: text }
      attach_quoted!(body, number, quoted_source_id)
      post("/message/sendText/#{instance_name}", body)
    end

    # media_type: "image" | "document" | "video"
    # media: base64 string
    def send_media(instance_name, number, media, media_type, caption: nil, filename: nil, quoted_source_id: nil)
      body = { number: format_number(number), mediatype: media_type, media: media, caption: caption.to_s }
      body[:fileName] = filename if filename.present?
      attach_quoted!(body, number, quoted_source_id)
      post("/message/sendMedia/#{instance_name}", body)
    end

    # audio: base64 string — enviado como voice note (OGG/Opus no WhatsApp)
    def send_audio(instance_name, number, audio, quoted_source_id: nil)
      body = { number: format_number(number), audio: audio }
      attach_quoted!(body, number, quoted_source_id)
      post("/message/sendWhatsAppAudio/#{instance_name}", body)
    end

    private

    def format_number(number)
      number.to_s.gsub(/[^0-9]/, "")
    end

    def attach_quoted!(body, number, source_id)
      return unless source_id.present?
      jid = "#{format_number(number)}@s.whatsapp.net"
      body[:quoted] = { key: { remoteJid: jid, fromMe: false, id: source_id } }
    end

    def map_evolution_status(raw)
      case raw
      when "open"             then "connected"
      when "close", "refused" then "disconnected"
      when "connecting"       then "connecting"
      end
    end

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
