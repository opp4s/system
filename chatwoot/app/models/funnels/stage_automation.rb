module Funnels
  class StageAutomation < ApplicationRecord
    self.table_name = 'funnel_stage_automations'

    AUTOMATION_TYPES = %w[webhook message task].freeze
    TRIGGER_EVENTS   = %w[on_enter on_leave].freeze

    belongs_to :funnel_stage, class_name: 'Funnels::Stage'
    belongs_to :account

    validates :automation_type, inclusion: { in: AUTOMATION_TYPES }
    validates :trigger_event,   inclusion: { in: TRIGGER_EVENTS }

    scope :active,    -> { where(active: true) }
    scope :on_enter,  -> { where(trigger_event: 'on_enter') }
    scope :on_leave,  -> { where(trigger_event: 'on_leave') }
    scope :ordered,   -> { order(:position) }

    # config schema por tipo:
    # webhook: { url: String, method: 'POST'|'GET', headers: Hash, include_card: Bool }
    # message: { template: String, inbox_id: Integer }  (envia via WhatsApp/canal primário do card)
    # task:    { title: String, due_in_hours: Integer }  (cria nota no card)
  end
end
