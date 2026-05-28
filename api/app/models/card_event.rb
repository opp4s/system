class CardEvent < ApplicationRecord
  TYPES = %w[
    card_created
    card_updated
    card_moved
    card_archived
    stage_changed
    note_added
    chatwoot_message
  ].freeze

  belongs_to :card
  belongs_to :workspace
  belongs_to :user, optional: true

  validates :event_type, inclusion: { in: TYPES }

  scope :chronological,        -> { order(created_at: :asc) }
  scope :reverse_chronological, -> { order(created_at: :desc) }
end
