class Message < ApplicationRecord
  MESSAGE_TYPES = %w[incoming outgoing].freeze

  belongs_to :workspace
  belongs_to :card,              optional: true
  belongs_to :contact,           optional: true
  belongs_to :conversation,      optional: true
  belongs_to :whatsapp_instance, optional: true

  validates :chatwoot_message_id, uniqueness: { scope: :workspace_id, allow_nil: true }, allow_nil: true
  validates :content,      presence: true
  validates :message_type, inclusion: { in: MESSAGE_TYPES }

  scope :not_embedded, -> { where(embedded_at: nil) }
  scope :for_card,     ->(card_id) { where(card_id: card_id).order(created_at: :asc) }
end
