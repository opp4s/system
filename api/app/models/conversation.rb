class Conversation < ApplicationRecord
  STATUSES = %w[open pending resolved].freeze

  belongs_to :workspace
  belongs_to :card, optional: true

  validates :chatwoot_conversation_id, presence: true,
            uniqueness: { scope: :workspace_id }
  validates :chatwoot_account_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :open,     -> { where(status: "open") }
  scope :resolved, -> { where(status: "resolved") }
  scope :pending,  -> { where(status: "pending") }

  def linked? = card_id.present?

  def chatwoot_url(base_url)
    "#{base_url}/app/accounts/#{chatwoot_account_id}/conversations/#{chatwoot_conversation_id}"
  end
end
