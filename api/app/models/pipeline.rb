class Pipeline < ApplicationRecord
  belongs_to :workspace
  has_many   :stages, -> { order(:position) }, dependent: :destroy
  has_many   :cards,       dependent: :destroy
  has_many   :automations, dependent: :destroy

  validates :name,     presence: true, length: { maximum: 100 }
  validates :color,    format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "deve ser um hex válido (#RRGGBB)" }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_position, on: :create

  scope :ordered, -> { order(:position) }

  def self.reorder!(ids, workspace:)
    transaction do
      ids.each_with_index do |id, idx|
        workspace.pipelines.where(id: id).update_all(position: idx)
      end
    end
  end

  private

  def set_position
    self.position ||= (workspace&.pipelines&.maximum(:position) || -1) + 1
  end
end
