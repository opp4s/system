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

    def send_message(conversation_id, content, private: false)
      post("/api/v1/accounts/#{@account_id}/conversations/#{conversation_id}/messages", {
        content:      content,
        message_type: "outgoing",
        private:      private
      })
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
