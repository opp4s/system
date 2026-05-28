module Automations
  module Actions
    class CreateTask
      def self.run(card, config)
        title = config["title"]
        due_in_days = config["due_in_days"].to_i
        due_at = due_in_days.positive? ? (Time.current + due_in_days.days) : nil
        
        card.card_events.create!(
          workspace_id: card.workspace_id,
          event_type: "task_created",
          payload: {
            title: title,
            due_in_days: due_in_days,
            due_at: due_at,
            automation: true
          }
        )
        
        { success: true, type: "create_task", title: title, due_in_days: due_in_days }
      rescue => e
        { success: false, type: "create_task", error: e.message }
      end
    end
  end
end
