module Automations
  class Executor
    MAX_EXECUTIONS_PER_HOUR = 10

    def initialize(card, trigger_type, context = {})
      @card = card
      @trigger_type = trigger_type
      @context = context
    end

    def run!
      # Circuit breaker: evita loops infinitos
      if exceeds_execution_limit?
        Rails.logger.warn "Automation circuit breaker triggered for card #{@card.id}"
        return
      end

      automations = find_matching_automations
      automations.each { |auto| execute_automation(auto) }
    end

    private

    def exceeds_execution_limit?
      hour_ago = 1.hour.ago
      AutomationLog.where(
        card_id: @card.id,
        created_at: hour_ago..
      ).count >= MAX_EXECUTIONS_PER_HOUR
    end

    def find_matching_automations
      Automation.active.where(
        pipeline_id: @card.pipeline_id,
        trigger_type: @trigger_type
      ).select { |a| matches_trigger_config?(a) && conditions_met?(a) }
    end

    def matches_trigger_config?(automation)
      case @trigger_type
      when "card_enters_stage"
        automation.trigger_config["stage_id"].to_i == @card.stage_id
      when "card_created"
        true
      else
        true
      end
    end

    def conditions_met?(automation)
      automation.conditions.all? { |cond| evaluate_condition(cond) }
    end

    def evaluate_condition(cond)
      field_value = resolve_field(cond["field"])
      operator = cond["operator"]
      target = cond["value"]

      case operator
      when "eq"        then field_value.to_s == target.to_s
      when "neq"       then field_value.to_s != target.to_s
      when "gt"        then field_value.to_f > target.to_f
      when "gte"       then field_value.to_f >= target.to_f
      when "lt"        then field_value.to_f < target.to_f
      when "lte"       then field_value.to_f <= target.to_f
      when "contains"  then field_value.to_s.include?(target.to_s)
      when "not_contains" then !field_value.to_s.include?(target.to_s)
      when "present"   then field_value.present?
      when "blank"     then field_value.blank?
      when "in"        then Array(target).include?(field_value.to_s)
      when "not_in"    then !Array(target).include?(field_value.to_s)
      else false
      end
    end

    def resolve_field(field)
      case field
      when "value"              then @card.value
      when "days_in_stage"      then @card.days_in_stage
      when "assigned_agent_id"  then @card.assigned_agent_id
      when "contact_name"       then @card.contact_name
      when "contact_phone"      then @card.contact_phone
      when "stage_type"         then @card.stage.stage_type
      else
        @card.custom_fields[field]
      end
    end

    def execute_automation(automation)
      results = automation.actions.map { |action| execute_action(action) }
      
      AutomationLog.create!(
        automation: automation,
        card: @card,
        workspace_id: @card.workspace_id,
        status: results.all? { |r| r[:success] } ? "success" : "failed",
        actions_executed: results,
        created_at: Time.current
      )
    end

    def execute_action(action)
      case action["type"]
      when "send_whatsapp"   then Automations::Actions::SendWhatsapp.run(@card, action["config"])
      when "move_card"       then Automations::Actions::MoveCard.run(@card, action["config"])
      when "assign_agent"    then Automations::Actions::AssignAgent.run(@card, action["config"])
      when "create_task"     then Automations::Actions::CreateTask.run(@card, action["config"])
      when "webhook"         then Automations::Actions::Webhook.run(@card, action["config"])
      when "update_field"    then Automations::Actions::UpdateField.run(@card, action["config"])
      else { success: false, error: "Unknown action: #{action["type"]}" }
      end
    rescue => e
      { success: false, error: e.message, type: action["type"] }
    end
  end
end
