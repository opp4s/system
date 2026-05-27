module Funnels
  class Card < ApplicationRecord
    self.table_name = 'funnel_cards'

    belongs_to :funnel,  class_name: 'Funnels::Funnel'
    belongs_to :stage,   class_name: 'Funnels::Stage',  foreign_key: :funnel_stage_id
    belongs_to :account
    belongs_to :assigned_agent, class_name: 'User', optional: true
    belongs_to :assigned_team,  class_name: 'Team', optional: true

    has_many :card_conversations, class_name: 'Funnels::CardConversation',
                                  foreign_key: :funnel_card_id, dependent: :destroy
    has_many :conversations, through: :card_conversations
    has_many :card_events,   class_name: 'Funnels::CardEvent',
                             foreign_key: :funnel_card_id, dependent: :destroy
    has_many :custom_field_values, class_name: 'Funnels::CustomFieldValue',
                                   foreign_key: :funnel_card_id, dependent: :destroy

    validates :title, presence: true, length: { maximum: 255 }
    validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    scope :active,    -> { where(archived_at: nil) }
    scope :archived,  -> { where.not(archived_at: nil) }
    scope :in_stage,  ->(stage_id) { where(funnel_stage_id: stage_id) }

    before_update :track_stage_change

    def primary_conversation
      card_conversations.find_by(is_primary: true)&.conversation
    end

    def days_in_stage
      reference = stage_changed_at || created_at
      ((Time.current - reference) / 1.day).floor
    end

    # Move o card para outra etapa, registra evento e dispara automações
    def move_to_stage!(new_stage, user: nil, reason: nil)
      old_stage = stage

      # Automações on_leave ANTES de mover
      Funnels::TriggerStageAutomationJob.perform_later(
        card_id: id, stage_id: old_stage.id,
        event: 'on_leave', user_id: user&.id
      )

      update!(
        funnel_stage_id:  new_stage.id,
        funnel_id:        new_stage.funnel_id,
        lost_reason:      (reason if new_stage.stage_type == 'lost'),
        stage_changed_at: Time.current
      )

      record_event('card_moved', user: user, payload: {
        from_stage_id:   old_stage.id,
        from_stage_name: old_stage.name,
        to_stage_id:     new_stage.id,
        to_stage_name:   new_stage.name,
        reason:          reason
      })

      # Automações on_enter APÓS mover
      Funnels::TriggerStageAutomationJob.perform_later(
        card_id: id, stage_id: new_stage.id,
        event: 'on_enter', user_id: user&.id
      )
    end

    def archive!(user: nil)
      update!(archived_at: Time.current)
      record_event('card_archived', user: user)
    end

    def record_event(type, user: nil, payload: {})
      card_events.create!(
        account_id: account_id,
        user_id:    user&.id,
        event_type: type,
        payload:    payload,
        created_at: Time.current
      )
    end

    private

    def track_stage_change
      self.stage_changed_at = Time.current if funnel_stage_id_changed?
    end
  end
end
