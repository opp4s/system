class Automation < ApplicationRecord
  TRIGGER_TYPES = %w[
    card_enters_stage
    card_created
    time_in_stage
    card_updated
  ].freeze

  belongs_to :workspace
  belongs_to :pipeline
  has_many :automation_logs, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :trigger_type, inclusion: { in: TRIGGER_TYPES }
  validate :conditions_format

  scope :active, -> { where(active: true) }
  scope :for_trigger, ->(trigger_type) { where(trigger_type: trigger_type) }
  scope :ordered, -> { order(:position) }

  private

  def conditions_format
    return if conditions.blank?
    conditions.each_with_index do |cond, i|
      errors.add(:conditions, "condition #{i}: field required") if cond["field"].blank?
      errors.add(:conditions, "condition #{i}: operator required") if cond["operator"].blank?
    end
  end
end
