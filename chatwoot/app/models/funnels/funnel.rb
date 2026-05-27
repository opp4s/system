module Funnels
  class Funnel < ApplicationRecord
    self.table_name = 'funnels'

    belongs_to :account
    has_many :stages,  -> { order(:position) }, class_name: 'Funnels::Stage',
                       foreign_key: :funnel_id, dependent: :destroy
    has_many :cards,   class_name: 'Funnels::Card',
                       foreign_key: :funnel_id, dependent: :destroy

    validates :name, presence: true, length: { maximum: 100 }
    validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    before_create :set_position

    scope :ordered, -> { order(:position, :created_at) }

    def self.ensure_default_for(account_id)
      return if exists?(account_id: account_id)

      Funnels::Seeder.seed_default_funnel(account_id)
    end

    private

    def set_position
      self.position ||= (self.class.where(account_id: account_id).maximum(:position) || -1) + 1
    end
  end
end
