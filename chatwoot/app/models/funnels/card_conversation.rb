module Funnels
  class CardConversation < ApplicationRecord
    self.table_name = 'funnel_card_conversations'

    belongs_to :funnel_card,  class_name: 'Funnels::Card'
    belongs_to :conversation

    validates :conversation_id, uniqueness: { scope: :funnel_card_id }

    before_create :ensure_single_primary

    private

    def ensure_single_primary
      return unless is_primary

      self.class.where(funnel_card_id: funnel_card_id, is_primary: true)
          .update_all(is_primary: false)
    end
  end
end
