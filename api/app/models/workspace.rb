class Workspace < ApplicationRecord
  PLANS = %w[starter pro enterprise].freeze

  belongs_to :owner, class_name: "User"
  has_many :workspace_memberships, dependent: :destroy
  has_many :members,         through: :workspace_memberships, source: :user
  has_many :pipelines,       dependent: :destroy
  has_many :cards,           dependent: :destroy
  has_one  :chatwoot_config, dependent: :destroy
  has_many :conversations,   dependent: :destroy
  has_many :contacts,        dependent: :destroy
  has_many :automations,     dependent: :destroy
  has_many :automation_logs, dependent: :destroy
  has_many :broadcasts,      dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "deve conter apenas letras minúsculas, números e hífens" }
  validates :plan, inclusion: { in: PLANS }

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    return if slug.present?

    base = name.to_s.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-").strip
    base = "workspace" if base.blank?

    candidate = base
    suffix     = 1
    while Workspace.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix   += 1
    end
    self.slug = candidate
  end
end
