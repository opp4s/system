module Broadcasts
  class ExecuteJob < ApplicationJob
    queue_as :default

    MESSAGES_PER_BATCH    = 10
    DELAY_BETWEEN_MESSAGES = 5   # seconds — ~12 msgs/min
    DELAY_BETWEEN_BATCHES  = 30  # seconds
    MAX_FAILURES_PERCENT   = 20

    def perform(broadcast_id)
      broadcast = Broadcast.find_by(id: broadcast_id)
      return unless broadcast
      return unless broadcast.status.in?(%w[scheduled running])

      broadcast.update!(status: "running", started_at: Time.current) if broadcast.scheduled?

      config = broadcast.workspace.chatwoot_config
      return broadcast.update!(status: "cancelled", completed_at: Time.current) unless config

      client = ::Chatwoot::Client.new(config)

      broadcast.broadcast_messages.pending.find_in_batches(batch_size: MESSAGES_PER_BATCH) do |batch|
        batch.each_with_index do |bm, idx|
          send_single_message(bm, broadcast, client)
          sleep DELAY_BETWEEN_MESSAGES if idx < batch.size - 1
        end

        broadcast.reload
        failure_pct = broadcast.total_recipients > 0 ?
          (broadcast.failed_count.to_f / broadcast.total_recipients * 100) : 0
        if failure_pct > MAX_FAILURES_PERCENT
          broadcast.update!(status: "cancelled", completed_at: Time.current)
          Rails.logger.error "[Broadcasts] #{broadcast.id} cancelled: failure rate #{failure_pct.round(1)}%"
          return
        end

        sleep DELAY_BETWEEN_BATCHES if broadcast.broadcast_messages.pending.exists?
      end

      broadcast.update!(status: "completed", completed_at: Time.current)
    rescue => e
      Rails.logger.error "[Broadcasts::ExecuteJob] broadcast=#{broadcast_id} error=#{e.message}"
      Broadcast.find_by(id: broadcast_id)&.update!(status: "cancelled", completed_at: Time.current)
    end

    private

    def send_single_message(bm, broadcast, client)
      contact = bm.contact
      return bm.update!(status: "failed", error_message: "Contato sem telefone") if contact.phone_number.blank?

      conv_id = find_conversation_id(contact, client)
      unless conv_id
        bm.update!(status: "failed", error_message: "Nenhuma conversa encontrada para #{contact.phone_number}")
        broadcast.increment!(:failed_count)
        return
      end

      content = interpolate(broadcast.message, contact)
      result  = client.send_message(conv_id, content)

      bm.update!(status: "sent", sent_at: Time.current, chatwoot_message_id: result[:id])
      broadcast.increment!(:sent_count)
    rescue => e
      bm.update!(status: "failed", error_message: e.message.truncate(255))
      broadcast.increment!(:failed_count)
    end

    def find_conversation_id(contact, client)
      # 1. Check local DB first (most recent linked conversation)
      local = Conversation.where(workspace: contact.workspace)
                          .where.not(chatwoot_conversation_id: nil)
                          .joins("INNER JOIN contacts ON contacts.workspace_id = conversations.workspace_id AND contacts.chatwoot_contact_id = conversations.contact_id::bigint")
                          .where("contacts.id = ?", contact.id)
                          .order(created_at: :desc).first
      return local.chatwoot_conversation_id if local

      # 2. Query Chatwoot API by contact_id
      return nil if contact.chatwoot_contact_id.blank?
      convs = client.contact_conversations(contact.chatwoot_contact_id)
      payload = convs[:payload] || []
      open_conv = payload.find { |c| c[:status] == "open" } || payload.first
      open_conv&.dig(:id)
    rescue => e
      Rails.logger.warn "[Broadcasts] find_conversation failed for contact=#{contact.id}: #{e.message}"
      nil
    end

    def interpolate(template, contact)
      template
        .gsub("{nome}",     contact.name.to_s)
        .gsub("{telefone}", contact.phone_number.to_s)
        .gsub("{email}",    contact.email.to_s)
    end
  end
end
