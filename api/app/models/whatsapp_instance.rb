class WhatsappInstance < ApplicationRecord
  STATUSES = %w[qr_pending connected disconnected].freeze

  belongs_to :workspace

  validates :instance_id,  presence: true

  validates :status,       inclusion: { in: STATUSES }
  validates :instance_id,  uniqueness: { scope: :workspace_id }
end
