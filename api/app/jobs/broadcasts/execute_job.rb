module Broadcasts
  class ExecuteJob < ApplicationJob
    queue_as :default

    MESSAGES_PER_BATCH     = 10
    DELAY_BETWEEN_MESSAGES = 5   # seconds
    DELAY_BETWEEN_BATCHES  = 30  # seconds
    MAX_FAILURES_PERCENT   = 20

    def perform(broadcast_id)
      broadcast = Broadcast.find_by(id: broadcast_id)
      return unless broadcast
      return unless broadcast.status.in?(%w[scheduled running])

      broadcast.update!(status: "running", started_at: Time.current) if broadcast.scheduled?

      wi = WhatsappInstance.find_by(workspace: broadcast.workspace, status: "connected")
      unless wi
        Rails.logger.warn "[Broadcasts] Nenhuma instância WhatsApp conectada para workspace #{broadcast.workspace_id}"
        return broadcast.update!(status: "cancelled", completed_at: Time.current)
      end

      evo_client = Whatsapp::EvolutionClient.new

      broadcast.broadcast_messages.pending.find_in_batches(batch_size: MESSAGES_PER_BATCH) do |batch|
        batch.each_with_index do |bm, idx|
          send_single_message(bm, broadcast, wi, evo_client)
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

    def send_single_message(bm, broadcast, wi, evo_client)
      contact = bm.contact
      return bm.update!(status: "failed", error_message: "Contato sem telefone") if contact.phone_number.blank?

      content = interpolate(broadcast.message, contact)
      resp    = evo_client.send_text(wi.instance_id, contact.phone_number, content)
      source_id = resp&.dig("key", "id") || resp&.dig(:key, :id)

      bm.update!(status: "sent", sent_at: Time.current)
      broadcast.increment!(:sent_count)
    rescue => e
      bm.update!(status: "failed", error_message: e.message.truncate(255))
      broadcast.increment!(:failed_count)
    end

    def interpolate(template, contact)
      template
        .gsub("{nome}",     contact.name.to_s)
        .gsub("{telefone}", contact.phone_number.to_s)
        .gsub("{email}",    contact.email.to_s)
    end
  end
end
