module Funnels
  module AccountConcern
    extend ActiveSupport::Concern

    included do
      has_many :funnels, class_name: 'Funnels::Funnel', dependent: :destroy
    end
  end
end
