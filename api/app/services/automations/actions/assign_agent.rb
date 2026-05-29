module Automations
  module Actions
    class AssignAgent
      def self.run(card, config)
        agent_id = if config["strategy"] == "round_robin"
          next_round_robin_agent(card.workspace, card.pipeline)
        else
          config["agent_id"]
        end
        
        return { success: false, type: "assign_agent", error: "Invalid agent" } unless agent_id

        old_agent_id = card.assigned_agent_id
        card.update!(assigned_agent_id: agent_id)
        
        card.card_events.create!(
          workspace_id: card.workspace_id,
          event_type: "automation_assigned",
          payload: {
            from_agent_id: old_agent_id,
            to_agent_id: agent_id,
            automation: true
          }
        )
        
        { success: true, type: "assign_agent", agent_id: agent_id }
      rescue => e
        { success: false, type: "assign_agent", error: e.message }
      end

      private

      def self.next_round_robin_agent(workspace, pipeline)
        agents = workspace.workspace_memberships
          .where(role: ["agent", "manager"])
          .pluck(:user_id)
        
        return nil if agents.empty?
        
        last_agent_id = Card
          .where(workspace_id: workspace.id, pipeline_id: pipeline.id)
          .where.not(assigned_agent_id: nil)
          .order(updated_at: :desc)
          .limit(1)
          .pluck(:assigned_agent_id)
          .first
        
        if last_agent_id && agents.include?(last_agent_id)
          current_index = agents.index(last_agent_id)
          agents[(current_index + 1) % agents.length]
        else
          agents.first
        end
      end
    end
  end
end
