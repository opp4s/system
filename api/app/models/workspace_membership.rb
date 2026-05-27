class WorkspaceMembership < ApplicationRecord
  ROLES = %w[owner admin agent].freeze

  belongs_to :workspace
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id, message: "já é membro deste workspace" }

  scope :accepted,  -> { where.not(accepted_at: nil) }
  scope :pending,   -> { where(accepted_at: nil) }
end
