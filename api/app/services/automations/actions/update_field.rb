module Automations
  module Actions
    class UpdateField
      def self.run(card, config)
        field = config["field"]
        value = config["value"]
        
        if card.respond_to?("#{field}=")
          card.update!(field => value)
        else
          custom_fields = card.custom_fields || {}
          custom_fields[field] = value
          card.update!(custom_fields: custom_fields)
        end
        
        card.card_events.create!(
          workspace_id: card.workspace_id,
          event_type: "automation_field_updated",
          payload: {
            field: field,
            value: value,
            automation: true
          }
        )
        
        { success: true, type: "update_field", field: field, value: value }
      rescue => e
        { success: false, type: "update_field", error: e.message }
      end
    end
  end
end
