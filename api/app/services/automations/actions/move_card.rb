module Automations
  module Actions
    class MoveCard
      def self.run(card, config)
        stage_id = config["stage_id"]
        stage = card.pipeline.stages.find(stage_id)
        
        old_stage = card.stage
        card.update!(stage: stage, stage_changed_at: Time.current)
        
        card.card_events.create!(
          workspace_id: card.workspace_id,
          event_type: "automation_moved",
          payload: { 
            from_stage_id: old_stage.id,
            from_stage_name: old_stage.name,
            to_stage_id: stage.id,
            to_stage_name: stage.name,
            automation: true
          }
        )
        
        { success: true, type: "move_card", stage_id: stage.id, stage_name: stage.name }
      rescue => e
        { success: false, type: "move_card", error: e.message }
      end
    end
  end
end
