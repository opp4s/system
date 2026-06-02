class Conversation < ApplicationRecord
  STATUSES = %w[open pending resolved].freeze

  belongs_to :workspace
  belongs_to :card, optional: true

  validates :status, inclusion: { in: STATUSES }

  scope :open,     -> { where(status: "open") }
  scope :resolved, -> { where(status: "resolved") }
  scope :pending,  -> { where(status: "pending") }

  def linked? = card_id.present?

end
