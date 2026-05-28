class BroadcastMessage < ApplicationRecord
  STATUSES = %w[pending sent failed].freeze

  belongs_to :broadcast
  belongs_to :contact

  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }
  scope :sent,    -> { where(status: "sent") }
  scope :failed,  -> { where(status: "failed") }
end
