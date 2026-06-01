module Chatwoot
  class Client
    class ApiError < StandardError
      attr_reader :status, :body
      def initialize(msg, status: nil, body: nil)
        super(msg)
        @status = status
        @body   = body
      end
    end

    # Cliente global usando ENV vars — para operações de inbox sem workspace config
    def self.from_env
      instance = allocate
      instance.instance_variable_set(:@base_url,   ENV.fetch("CHATWOOT_URL", "").chomp("/"))
      instance.instance_variable_set(:@token,      ENV.fetch("CHATWOOT_API_TOKEN", ""))
      instance.instance_variable_set(:@account_id, ENV.fetch("CHATWOOT_ACCOUNT_ID", "1"))
      instance
    end

    def initialize(workspace_or_config)
      config = workspace_or_config.is_a?(ChatwootConfig) \
        ? workspace_or_config \
        : workspace_or_config.chatwoot_config

      raise ArgumentError, "Workspace sem configuração Chatwoot" unless config

      @base_url   = config.chatwoot_url.chomp("/")
      @token      = config.decrypted_token
      @account_id = config.chatwoot_account_id
    end

    # ── Account ──────────────────────────────────────────────────────────────

    def account_info
      get("/api/v1/accounts/#{@account_id}")
    end

    # ── Conversations ─────────────────────────────────────────────────────────

    def conversations(params = {})
      get("/api/v1/accounts/#{@account_id}/conversations", params)
    end

    def conversation(conversation_id)
      get("/api/v1/accounts/#{@account_id}/conversations/#{conversation_id}")
    end

    # ── Messages ──────────────────────────────────────────────────────────────

    def messages(conversation_id)
      get("/api/v1/accounts/#{@account_id}/conversations/#{conversation_id}/messages")
    end

    def send_message(conversation_id, content, private: false, in_reply_to: nil)
      body = { content: content, message_type: "outgoing", private: private }
      body[:content_attributes] = { in_reply_to: in_reply_to } if in_reply_to.present?
      post("/api/v1/accounts/#{@account_id}/conversations/#{conversation_id}/messages", body)
    end

    # Envia mensagem com attachment via multipart (não usa Faraday — Net::HTTP direto)
    def send_message_with_attachment(conversation_id, content:, attachment:, private: false, in_reply_to: nil)
      uri      = URI("#{@base_url}/api/v1/accounts/#{@account_id}/conversations/#{conversation_id}/messages")
      boundary = SecureRandom.hex(16)

      body = build_multipart_body(boundary, content, attachment, private, in_reply_to)

      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = uri.scheme == "https"
      http.read_timeout = 30

      req = Net::HTTP::Post.new(uri)
      req["api_access_token"] = @token
      req["Content-Type"]     = "multipart/form-data; boundary=#{boundary}"
      req.body = body

      resp = http.request(req)
      unless resp.is_a?(Net::HTTPSuccess)
        msg = begin; JSON.parse(resp.body)["message"]; rescue; resp.body.to_s[0..100]; end
        raise ApiError.new(msg || "HTTP #{resp.code}", status: resp.code.to_i)
      end
      JSON.parse(resp.body, symbolize_names: true)
    end

    # ── Contacts ──────────────────────────────────────────────────────────────

    def contacts(params = {})
      get("/api/v1/accounts/#{@account_id}/contacts", params)
    end

    def contact(contact_id)
      get("/api/v1/accounts/#{@account_id}/contacts/#{contact_id}")
    end

    def find_contact_by_phone(phone)
      get("/api/v1/accounts/#{@account_id}/contacts/search", { q: phone })
    end

    def contact_conversations(contact_id)
      get("/api/v1/accounts/#{@account_id}/contacts/#{contact_id}/conversations")
    end

    # ── Inboxes ───────────────────────────────────────────────────────────────

    def inboxes
      get("/api/v1/accounts/#{@account_id}/inboxes")
    end

    def find_inbox_by_name(name)
      data = inboxes
      list = data.is_a?(Hash) ? (data[:payload] || data["payload"] || []) : Array(data)
      list.find { |i| (i[:name] || i["name"]) == name }
    end

    def delete_inbox(inbox_id)
      resp = conn.delete("/api/v1/accounts/#{@account_id}/inboxes/#{inbox_id}")
      return true if resp.status.between?(200, 299) || resp.status == 404
      raise ApiError.new("Chatwoot retornou #{resp.status} ao deletar inbox", status: resp.status)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise ApiError.new("Chatwoot indisponível: #{e.message}")
    end

    # ── Webhooks ──────────────────────────────────────────────────────────────

    def webhooks
      get("/api/v1/accounts/#{@account_id}/webhooks")
    end

    def create_webhook(url, subscriptions: %w[message_created conversation_created conversation_status_changed])
      post("/api/v1/accounts/#{@account_id}/webhooks", {
        webhook: { url: url, subscriptions: subscriptions }
      })
    end

    def delete_webhook(webhook_id)
      conn.delete("/api/v1/accounts/#{@account_id}/webhooks/#{webhook_id}")
    end

    private

    def conn
      @conn ||= Faraday.new(url: @base_url) do |f|
        f.headers["api_access_token"] = @token
        f.headers["Content-Type"]     = "application/json"
        f.options.timeout             = 15
        f.options.open_timeout        = 5
        f.use Faraday::Retry::Middleware, max: 2, interval: 0.5,
              retry_statuses: [429, 503]
      end
    end

    def build_multipart_body(boundary, content, attachment, private_msg, in_reply_to = nil)
      body = +"".encode("ASCII-8BIT")

      field = ->(name, value) {
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n"
        body << value.to_s.encode("UTF-8").force_encoding("ASCII-8BIT")
        body << "\r\n"
      }

      field.call("content",      content.to_s)
      field.call("message_type", "outgoing")
      field.call("private",      private_msg.to_s)
      field.call("content_attributes[in_reply_to]", in_reply_to.to_s) if in_reply_to.present?

      body << "--#{boundary}\r\n"
      body << "Content-Disposition: form-data; name=\"attachments[]\"; filename=\"#{attachment.original_filename.encode('UTF-8')}\"\r\n".encode("ASCII-8BIT")
      body << "Content-Type: #{attachment.content_type}\r\n\r\n".encode("ASCII-8BIT")
      body << attachment.read.force_encoding("ASCII-8BIT")
      body << "\r\n"
      body << "--#{boundary}--\r\n"
      body
    end

    def get(path, params = {})
      resp = conn.get(path, params)
      handle_response(resp)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise ApiError.new("Chatwoot indisponível: #{e.message}")
    end

    def post(path, body = {})
      resp = conn.post(path) { |req| req.body = body.to_json }
      handle_response(resp)
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
      raise ApiError.new("Chatwoot indisponível: #{e.message}")
    end

    def handle_response(resp)
      unless resp.status.between?(200, 299)
        raise ApiError.new(
          "Chatwoot retornou #{resp.status}",
          status: resp.status,
          body:   resp.body
        )
      end
      JSON.parse(resp.body, symbolize_names: true)
    end
  end
end
