class WhatsappInstance < ApplicationRecord
  STATUSES = %w[qr_pending connecting connected disconnected].freeze

  belongs_to :workspace
  belongs_to :pipeline, optional: true

  validates :instance_id, presence: true
  validates :status,      inclusion: { in: STATUSES }
  validates :instance_id, uniqueness: { scope: :workspace_id }
  validate  :pipeline_belongs_to_workspace

  private

  def pipeline_belongs_to_workspace
    return unless pipeline_id.present?
    unless workspace.pipelines.exists?(id: pipeline_id)
      errors.add(:pipeline_id, "não pertence a este workspace")
    end
  end
end
