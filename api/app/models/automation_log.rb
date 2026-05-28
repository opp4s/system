class AutomationLog < ApplicationRecord
  belongs_to :automation
  belongs_to :card
  belongs_to :workspace

  validates :status, inclusion: { in: %w[success failed skipped] }

  scope :recent, -> { order(created_at: :desc) }
end
