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
      when "conversation_created"        then handle_conversation_created(workspace)
      when "conversation_status_changed" then handle_status_changed(workspace)
      when "message_created"             then handle_message_created(workspace)
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
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )

      conv.assign_attributes(
        chatwoot_account_id: @account_id,
        inbox_id:            (conv_data[:inbox_id] || conv_data.dig(:conversation, :inbox_id)).to_i,
        contact_id:          extract_contact_id(conv_data),
        status:              normalize_status(conv_data[:status] || conv_data.dig(:conversation, :status)),
        last_activity_at:    Time.current,
        meta:                build_meta(conv_data)
      )
      conv.save!

      # Auto-link to card if not already linked
      try_auto_link(workspace, conv) unless conv.linked?
    end

    def handle_status_changed(workspace)
      conv_id = @payload[:id].to_i
      return unless conv_id > 0

      conv = Conversation.find_by(
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )
      return unless conv

      new_status = normalize_status(@payload[:status])
      conv.update!(status: new_status, last_activity_at: Time.current)

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
        broadcast(conv.card, "chatwoot_status_changed",
                  conversation_id: conv_id, status: new_status)
      end
    end

    def handle_message_created(workspace)
      msg          = @payload
      conv_id      = (msg.dig(:conversation, :id) || msg[:conversation_id]).to_i
      message_type = msg[:message_type].to_s
      content      = msg[:content].to_s
      return if content.blank? || conv_id == 0

      conv = Conversation.find_or_initialize_by(
        workspace:                workspace,
        chatwoot_conversation_id: conv_id
      )

      unless conv.persisted?
        conv.assign_attributes(
          chatwoot_account_id: @account_id,
          status:              "open",
          last_activity_at:    Time.current
        )
        conv.save!
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

      broadcast(conv.card, "chatwoot_message_received",
                conversation_id: conv_id,
                message_type:    message_type,
                content:         content,
                sender_name:     sender_name)
    end

    # ── Auto-link ─────────────────────────────────────────────────────────────

    def try_auto_link(workspace, conv)
      return if conv.contact_id.blank?

      contact = Contact.find_by(
        workspace:           workspace,
        chatwoot_contact_id: conv.contact_id
      )
      return unless contact

      card = nil
      if contact.phone_number.present?
        card = workspace.cards.active
                        .where(contact_phone: contact.phone_number)
                        .order(created_at: :desc)
                        .first
      end

      if card
        link_conv_to_card(conv, card, workspace)
        return
      end

      auto_create_card(workspace, conv, contact)
    end

    def auto_create_card(workspace, conv, contact)
      config = workspace.chatwoot_config
      return unless config&.settings&.dig("auto_create_card")

      pipeline_id = config.settings["auto_create_pipeline_id"].to_i
      stage_id    = config.settings["auto_create_stage_id"].to_i
      return unless pipeline_id > 0 && stage_id > 0

      pipeline = workspace.pipelines.find_by(id: pipeline_id)
      stage    = pipeline&.stages&.find_by(id: stage_id)
      return unless pipeline && stage

      card = workspace.cards.create!(
        pipeline:         pipeline,
        stage:            stage,
        title:            contact.name,
        contact_name:     contact.name,
        contact_phone:    contact.phone_number,
        contact_email:    contact.email,
        stage_changed_at: Time.current
      )

      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "card_created",
        payload:    {
          title:        card.title,
          stage_id:     stage.id,
          auto_created: true,
          source:       "chatwoot_webhook"
        }
      )

      link_conv_to_card(conv, card, workspace)

      ActionCable.server.broadcast(
        "pipeline_#{pipeline.id}",
        { event: "card_created", card_id: card.id, title: card.title }
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[WebhookProcessor] auto_create_card failed: #{e.message}"
    end

    def link_conv_to_card(conv, card, workspace)
      conv.update!(card: card)

      CardEvent.create!(
        card:       card,
        workspace:  workspace,
        event_type: "conversation_linked",
        payload:    { chatwoot_conversation_id: conv.chatwoot_conversation_id }
      )

      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        { event: "conversation_linked", card_id: card.id,
          chatwoot_conversation_id: conv.chatwoot_conversation_id }
      )
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
        inbox_id:    (data[:inbox_id] || data.dig(:conversation, :inbox_id)).to_i,
        sender_name: data.dig(:meta, :sender, :name) ||
                     data.dig(:contact_inbox, :contact, :name)
      }.compact
    end

    def broadcast(card, event_type, extra = {})
      ActionCable.server.broadcast(
        "pipeline_#{card.pipeline_id}",
        { event: event_type, card_id: card.id }.merge(extra)
      )
    end
  end
end
