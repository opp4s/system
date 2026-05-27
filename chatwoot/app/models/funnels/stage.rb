module Funnels
  class Stage < ApplicationRecord
    self.table_name = 'funnel_stages'

    STAGE_TYPES = %w[intermediate won lost].freeze

    belongs_to :funnel, class_name: 'Funnels::Funnel'
    has_many :cards, class_name: 'Funnels::Card', foreign_key: :funnel_stage_id, dependent: :nullify

    validates :name, presence: true, length: { maximum: 100 }
    validates :stage_type, inclusion: { in: STAGE_TYPES }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :win_probability, numericality: { in: 0..100 }, allow_nil: true

    scope :ordered, -> { order(:position) }
    scope :intermediate, -> { where(stage_type: 'intermediate') }
    scope :terminal, -> { where(stage_type: %w[won lost]) }

    before_create :set_position

    def terminal?
      %w[won lost].include?(stage_type)
    end

    private

    def set_position
      self.position ||= (self.class.where(funnel_id: funnel_id).maximum(:position) || -1) + 1
    end
  end
end
