class Contact < ApplicationRecord
  belongs_to :workspace

  validates :chatwoot_contact_id, uniqueness: { scope: :workspace_id, allow_nil: true }, allow_nil: true
  validates :name, presence: true

  scope :ordered,     -> { order(name: :asc) }
  scope :search_by,   ->(q) {
    term = "%#{q.strip}%"
    where("name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ?", term, term, term)
  }

  def conversations
    workspace.conversations.where(contact_id: chatwoot_contact_id)
  end
end
