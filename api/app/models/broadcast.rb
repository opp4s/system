class Broadcast < ApplicationRecord
  STATUSES    = %w[draft scheduled running completed cancelled].freeze
  MEDIA_TYPES = %w[image document audio video].freeze

  belongs_to :workspace
  belongs_to :pipeline, optional: true
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id, optional: true
  has_many   :broadcast_messages, dependent: :destroy

  validates :name,    presence: true, length: { maximum: 100 }
  validates :message, presence: true
  validates :status,  inclusion: { in: STATUSES }
  validates :media_type, inclusion: { in: MEDIA_TYPES }, allow_blank: true

  scope :draft,      -> { where(status: "draft") }
  scope :scheduled,  -> { where(status: "scheduled") }
  scope :running,    -> { where(status: "running") }
  scope :completed,  -> { where(status: "completed") }
  scope :recent,     -> { order(created_at: :desc) }
  scope :due,        -> { scheduled.where("scheduled_at <= ?", Time.current) }

  def editable?   = draft?
  def cancellable? = status.in?(%w[scheduled running])
  def delivery_rate
    return 0 if total_recipients == 0
    (sent_count.to_f / total_recipients * 100).round(1)
  end

  STATUSES.each { |s| define_method("#{s}?") { status == s } }
end
