class CustomFieldDefinition < ApplicationRecord
  FIELD_TYPES = %w[text number select boolean date phone email textarea].freeze

  belongs_to :workspace
  belongs_to :pipeline, optional: true

  validates :name,       presence: true, length: { maximum: 100 }
  validates :field_type, inclusion: { in: FIELD_TYPES }
  validates :position,   numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :options_valid_for_type

  scope :ordered, -> { order(:position, :id) }
  scope :global,  -> { where(pipeline_id: nil) }
  scope :for_pipeline, ->(pid) { where(pipeline_id: [nil, pid]) }

  private

  def options_valid_for_type
    return unless field_type == "select"
    choices = options.dig("choices")
    unless choices.is_a?(Array) && choices.any?
      errors.add(:options, "deve conter uma lista 'choices' para o tipo select")
    end
  end
end
