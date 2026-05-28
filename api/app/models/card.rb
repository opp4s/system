class Card < ApplicationRecord
  belongs_to :pipeline
  belongs_to :stage
  belongs_to :workspace
  belongs_to :assigned_agent, class_name: "User", foreign_key: :assigned_agent_id, optional: true

  has_many :card_events, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :currency, length: { is: 3 }, allow_blank: true

  # Garante que stage e pipeline pertencem ao mesmo workspace
  validate :stage_belongs_to_pipeline

  before_create :set_stage_changed_at

  scope :active,    -> { where(archived_at: nil) }
  scope :archived,  -> { where.not(archived_at: nil) }
  scope :in_stage,  ->(stage_id) { where(stage_id: stage_id) }
  scope :ordered,   -> { order(created_at: :desc) }

  def active?   = archived_at.nil?
  def archived? = archived_at.present?

  def days_in_stage
    since = stage_changed_at || created_at
    ((Time.current - since) / 1.day).floor
  end

  # Move o card para uma nova stage, registrando o evento de auditoria.
  def move_to_stage!(new_stage, user: nil, reason: nil)
    old_stage = stage

    transaction do
      update!(
        stage:           new_stage,
        stage_changed_at: Time.current,
        lost_reason:     (reason if new_stage.lost?)
      )

      CardEvent.create!(
        card:       self,
        workspace:  workspace,
        user_id:    user&.id,
        event_type: "card_moved",
        payload:    {
          from_stage_id:   old_stage.id,
          from_stage_name: old_stage.name,
          to_stage_id:     new_stage.id,
          to_stage_name:   new_stage.name,
          lost_reason:     reason
        }
      )
    end
  end

  def archive!(user: nil)
    transaction do
      update!(archived_at: Time.current)

      CardEvent.create!(
        card:       self,
        workspace:  workspace,
        user_id:    user&.id,
        event_type: "card_archived",
        payload:    { archived_at: archived_at }
      )
    end
  end

  private

  def set_stage_changed_at
    self.stage_changed_at ||= Time.current
  end

  def stage_belongs_to_pipeline
    return unless stage && pipeline

    unless stage.pipeline_id == pipeline.id
      errors.add(:stage, "não pertence ao pipeline selecionado")
    end
  end
end
