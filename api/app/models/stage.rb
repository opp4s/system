class Stage < ApplicationRecord
  TYPES = %w[intermediate won lost].freeze

  belongs_to :pipeline
  has_many   :cards, dependent: :restrict_with_error

  validates :name,       presence: true, length: { maximum: 100 }
  validates :stage_type, inclusion: { in: TYPES }
  validates :color,      format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "deve ser um hex válido (#RRGGBB)" }
  validates :position,   numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :win_probability, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  before_validation :set_position, on: :create

  scope :ordered,      -> { order(:position) }
  scope :intermediate, -> { where(stage_type: "intermediate") }
  scope :won,          -> { where(stage_type: "won") }
  scope :lost,         -> { where(stage_type: "lost") }

  def terminal? = stage_type.in?(%w[won lost])
  def won?      = stage_type == "won"
  def lost?     = stage_type == "lost"

  def self.reorder!(ids, pipeline:)
    transaction do
      ids.each_with_index do |id, idx|
        pipeline.stages.where(id: id).update_all(position: idx)
      end
    end
  end

  private

  def set_position
    self.position ||= (pipeline&.stages&.maximum(:position) || -1) + 1
  end
end
