class Contact < ApplicationRecord
  belongs_to :workspace

  validates :name, presence: true

  scope :ordered,   -> { order(name: :asc) }
  scope :search_by, ->(q) {
    term = "%#{q.strip}%"
    where("name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ?", term, term, term)
  }
end
