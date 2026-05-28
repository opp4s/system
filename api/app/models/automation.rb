class Automation < ApplicationRecord
  TRIGGER_TYPES = %w[
    card_enters_stage
    card_created
    time_in_stage
    card_updated
  ].freeze

  OPERATORS = %w[
    eq neq
    gt gte lt lte
    contains not_contains starts_with
    present blank
    in not_in
  ].freeze

  AVAILABLE_FIELDS = {
    value: { type: "number", label: "Valor do Card" },
    days_in_stage: { type: "number", label: "Dias na Etapa" },
    assigned_agent_id: { type: "select", label: "Agente Atribuído" },
    contact_name: { type: "text", label: "Nome do Contato" },
    contact_phone: { type: "text", label: "Telefone do Contato" },
    contact_email: { type: "text", label: "Email do Contato" },
    stage_type: { type: "select", label: "Tipo de Etapa", values: %w[intermediate won lost] },
    title: { type: "text", label: "Título do Card" },
    archived_at: { type: "text", label: "Data de Arquivo" }
  }.freeze

  belongs_to :workspace
  belongs_to :pipeline
  has_many :automation_logs, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :trigger_type, inclusion: { in: TRIGGER_TYPES }
  validate :conditions_format_and_operators
  validate :actions_not_empty

  scope :active, -> { where(active: true) }
  scope :for_trigger, ->(trigger_type) { where(trigger_type: trigger_type) }
  scope :ordered, -> { order(:position) }

  private

  def conditions_format_and_operators
    return if conditions.blank?
    
    conditions.each_with_index do |cond, i|
      errors.add(:conditions, "condition #{i}: field required") if cond["field"].blank?
      errors.add(:conditions, "condition #{i}: operator required") if cond["operator"].blank?
      errors.add(:conditions, "condition #{i}: value required") if cond["value"].nil? && !%w[present blank].include?(cond["operator"])
      
      unless OPERATORS.include?(cond["operator"])
        errors.add(:conditions, "condition #{i}: invalid operator '#{cond["operator"]}'. Allowed: #{OPERATORS.join(', ')}")
      end
      
      if %w[gt gte lt lte].include?(cond["operator"])
        unless cond["value"].is_a?(Numeric) || cond["value"].to_s.match?(/^\d+(\.\d+)?$/)
          errors.add(:conditions, "condition #{i}: value must be numeric for operator #{cond["operator"]}")
        end
      end
      
      if %w[in not_in].include?(cond["operator"])
        unless cond["value"].is_a?(Array)
          errors.add(:conditions, "condition #{i}: value must be an array for operator #{cond["operator"]}")
        end
      end
    end
  end

  def actions_not_empty
    errors.add(:actions, "deve ter ao menos uma ação") if actions.blank?
  end
end
