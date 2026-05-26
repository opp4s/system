class WhatsappLiteEvent < ApplicationRecord
  belongs_to :account

  validates :instance_id, presence: true
  validates :event_type,  presence: true

  scope :recent,     -> { order(created_at: :desc) }
  scope :for_instance, ->(id) { where(instance_id: id) }
  scope :failures,   -> { where(status: 'failed') }

  # Convenience method para registrar eventos sem bloquear o fluxo principal.
  # Erros de escrita são logados mas não propagados.
  def self.track!(account_id:, instance_id:, event_type:, source_id: nil, status: 'success', metadata: {})
    create!(
      account_id:  account_id,
      instance_id: instance_id,
      event_type:  event_type,
      source_id:   source_id,
      status:      status,
      metadata:    metadata
    )
  rescue StandardError => e
    Rails.logger.tagged('whatsapp_lite', 'audit') do
      Rails.logger.error "failed to track event: #{e.message}"
    end
  end
end
