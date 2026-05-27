module Funnels
  class CardEvent < ApplicationRecord
    self.table_name = 'funnel_card_events'

    EVENT_TYPES = %w[
      card_created card_moved card_archived card_updated
      stage_changed funnel_transferred note_added
      conversation_linked conversation_unlinked
    ].freeze

    belongs_to :funnel_card, class_name: 'Funnels::Card'
    belongs_to :account
    belongs_to :user, optional: true

    validates :event_type, inclusion: { in: EVENT_TYPES }

    scope :recent, -> { order(created_at: :desc) }
  end
end
