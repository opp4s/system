module Funnels
  class CustomFieldValue < ApplicationRecord
    self.table_name = 'funnel_custom_field_values'

    belongs_to :funnel_card,      class_name: 'Funnels::Card'
    belongs_to :custom_attribute

    validates :custom_attribute_id, uniqueness: { scope: :funnel_card_id }

    def value
      case custom_attribute.attribute_display_type
      when 'text', 'list'   then value_text
      when 'number'         then value_numeric
      when 'checkbox'       then value_boolean
      when 'date'           then value_date
      else value_text
      end
    end

    def value=(val)
      case custom_attribute.attribute_display_type
      when 'text', 'list'   then self.value_text    = val
      when 'number'         then self.value_numeric  = val
      when 'checkbox'       then self.value_boolean  = val
      when 'date'           then self.value_date     = val
      else self.value_text = val
      end
    end
  end
end
