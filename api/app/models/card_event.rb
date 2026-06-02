class CardEvent < ApplicationRecord
  TYPES = %w[
    card_created
    card_updated
    card_moved
    card_archived
    stage_changed
    note_added
    chatwoot_message
    whatsapp_message
    message_sent
    conversation_linked
    conversation_unlinked
    automation_message_sent
    automation_moved
    automation_assigned
    automation_field_updated
    task_created
  ].freeze

  belongs_to :card
  belongs_to :workspace
  belongs_to :user, optional: true

  validates :event_type, inclusion: { in: TYPES }

  scope :chronological,         -> { order(created_at: :asc) }
  scope :reverse_chronological, -> { order(created_at: :desc) }
end
