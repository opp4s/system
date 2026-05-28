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

  def provision_default_stages!
    [
      { name: "Novo Lead",   stage_type: "intermediate", color: "#6C757D", win_probability: 10,  position: 0 },
      { name: "Qualificado", stage_type: "intermediate", color: "#0D6EFD", win_probability: 25,  position: 1 },
      { name: "Proposta",    stage_type: "intermediate", color: "#FFC107", win_probability: 50,  position: 2 },
      { name: "Ganho",       stage_type: "won",          color: "#28A745", win_probability: 100, position: 3 },
      { name: "Perdido",     stage_type: "lost",         color: "#DC3545", win_probability: 0,   position: 4 },
    ].each { |attrs| stages.create!(attrs) }
  rescue => e
    Rails.logger.error "[Pipeline] provision_default_stages! failed: #{e.message}"
  end

  private

  def set_position
    self.position ||= (workspace&.pipelines&.maximum(:position) || -1) + 1
  end
end
