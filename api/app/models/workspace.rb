class Workspace < ApplicationRecord
  PLANS = %w[starter pro enterprise].freeze

  belongs_to :owner, class_name: "User"
  has_many :workspace_memberships, dependent: :destroy
  has_many :members,         through: :workspace_memberships, source: :user
  has_many :pipelines,       dependent: :destroy
  has_many :cards,           dependent: :destroy
  has_many :conversations,   dependent: :destroy
  has_many :contacts,        dependent: :destroy
  has_many :automations,     dependent: :destroy
  has_many :automation_logs, dependent: :destroy
  has_many :broadcasts,               dependent: :destroy
  has_many :custom_field_definitions, dependent: :destroy
  has_many :whatsapp_instances,       dependent: :destroy
  has_many :messages,                 dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "deve conter apenas letras minúsculas, números e hífens" }
  validates :plan, inclusion: { in: PLANS }

  before_validation :generate_slug, on: :create
  after_create :provision_default_pipeline

  def provision_default_pipeline
    pipeline = pipelines.create!(
      name:       "Pipeline de Vendas",
      is_default: true,
      position:   0
    )
    [
      { name: "Novo Lead",        stage_type: "intermediate", color: "#6C757D", win_probability: 10,  position: 0 },
      { name: "Qualificado",      stage_type: "intermediate", color: "#0D6EFD", win_probability: 25,  position: 1 },
      { name: "Proposta Enviada", stage_type: "intermediate", color: "#FFC107", win_probability: 50,  position: 2 },
      { name: "Negociação",       stage_type: "intermediate", color: "#FD7E14", win_probability: 75,  position: 3 },
      { name: "Ganho",            stage_type: "won",          color: "#28A745", win_probability: 100, position: 4 },
      { name: "Perdido",          stage_type: "lost",         color: "#DC3545", win_probability: 0,   position: 5 },
    ].each { |attrs| pipeline.stages.create!(attrs) }
  rescue => e
    Rails.logger.error "[Workspace] provision_default_pipeline failed: #{e.message}"
  end

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
