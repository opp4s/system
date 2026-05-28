module Chatwoot
  class WebhookProcessor
    def initialize(payload)
      @payload    = payload.deep_symbolize_keys
      @event_type = @payload[:event]
      @account_id = (@payload.dig(:account, :id) || @payload[:account_id]).to_s
    end

    def call
      workspace = find_workspace
      return false unless workspace

      case @event_type
      when "conversation_created"    then handle_conversation_created(workspace)
      when "conversation_status_changed" then handle_status_changed(workspace)
      when "message_created"         then handle_message_created(workspace)
      end

      true
    end

    private

    def find_workspace
      config = ChatwootConfig.find_by(chatwoot_account_id: @account_id)
      config&.workspace
    end

    # ── Handlers ──────────────────────────────────────────────────────────────

    def handle_conversation_created(workspace)
      conv_data = @payload
      conv_id   = (conv_data[:id] || conv_data.dig(:conversation, :id)).to_i
      return unless conv_id > 0

      conv = Conversation.find_or_initialize_by(
        workspace:               workspace,
        chatwoot_conversation_id: conv_id
      )

      conv.assign_attributes(
        chatwoot_account_id:  @account_id,
        inbox_id:             (conv_data[:inbox_id] || conv_data.dig(:conversation, :inbox_id)).to_i,
        contact_id:           extract_contact_id(conv_data),
        status:               normalize_status(conv_data[:status] || conv_data.dig(:conversation, :status)),
        last_activity_at:     Time.current,
        meta:                 build_meta(conv_data)
      )
      conv.save!
    end

    def handle_status_changed(workspace)
      conv_id = @payload[:id].to_i
      return unless conv_id > 0

      conv = Conversation.find_by(
        workspace:               workspace,
        chatwoot_conversation_id: conv_id
      )
      return unless conv

      new_status = normalize_status(@payload[:status])
      conv.update!(status: new_status, last_activity_at: Time.current)

      # If linked to a card, add timeline event
      if conv.linked?
        CardEvent.create!(
          card:       conv.card,
          workspace:  workspace,
          event_type: "chatwoot_message",
          payload:    {
            subtype:         "status_changed",
            status:          new_status,
            conversation_id: conv_id
          }
        )
        broadcast_card_event(conv.card, "chatwoot_status_changed", {
          conversation_id: conv_id,
          status:          new_status
        })
      end
    end

    def handle_message_created(workspace)
      msg          = @payload
      conv_id      = (msg.dig(:conversation, :id) || msg[:conversation_id]).to_i
      message_type = msg[:message_type].to_s   # "incoming" | "outgoing"
      content      = msg[:content].to_s
      return if content.blank? || conv_id == 0

      conv = Conversation.find_by(
        workspace:               workspace,
        chatwoot_conversation_id: conv_id
      )

      # Upsert conversation if it doesn't exist yet
      unless conv
        conv = Conversation.create!(
          workspace:               workspace,
          chatwoot_conversation_id: conv_id,
          chatwoot_account_id:     @account_id,
          status:                  "open",
          last_activity_at:        Time.current
        )
      else
        conv.update!(last_activity_at: Time.current)
      end

      return unless conv.linked?

      sender_name = msg.dig(:sender, :name).to_s

      CardEvent.create!(
        card:       conv.card,
        workspace:  workspace,
        event_type: "chatwoot_message",
        payload:    {
          subtype:         "message",
          message_type:    message_type,
          content:         content,
          sender_name:     sender_name,
          conversation_id: conv_id,
          message_id:      msg[:id]
        }
      )

      broadcast_card_event(conv.card, "chatwoot_message_received", {
        conversation_id: conv_id,
        message_type:    message_type,
        content:         content,
        sender_name:     sender_name
      })
    end

    # ── Helpers ───────────────────────────────────────────────────────────────

    def extract_contact_id(data)
      (
        data.dig(:meta, :sender, :id) ||
        data.dig(:contact_inbox, :contact, :id) ||
        data[:contact_id]
      ).to_i.then { |v| v > 0 ? v : nil }
    end

    def normalize_status(raw)
      s = raw.to_s.downcase
      Conversation::STATUSES.include?(s) ? s : "open"
    end

    def build_meta(data)
      {
        inbox_id:     (data[:inbox_id] || data.dig(:conversation, :inbox_id)).to_i,
        sender_name:  data.dig(:meta, :sender, :name) || data.dig(:contact_inbox, :contact, :name)
      }.compact
    end

    def broadcast_card_event(card, event_type, extra = {})
      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        { event: event_type, card_id: card.id }.merge(extra)
      )
    end
  end
end
