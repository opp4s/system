module Automations
  class Executor
    MAX_EXECUTIONS_PER_HOUR = 10

    def initialize(card, trigger_type, context = {})
      @card = card
      @trigger_type = trigger_type
      @context = context
    end

    def run!
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
      when "eq"           then safe_equals(field_value, target)
      when "neq"          then !safe_equals(field_value, target)
      when "gt"           then safe_numeric_compare(field_value, target, :>)
      when "gte"          then safe_numeric_compare(field_value, target, :>=)
      when "lt"           then safe_numeric_compare(field_value, target, :<)
      when "lte"          then safe_numeric_compare(field_value, target, :<=)
      when "contains"     then safe_string_op(field_value, :include?, target)
      when "not_contains" then !safe_string_op(field_value, :include?, target)
      when "starts_with"  then safe_string_op(field_value, :start_with?, target)
      when "present"      then field_value.present?
      when "blank"        then field_value.blank?
      when "in"           then Array(target).map(&:to_s).include?(field_value.to_s)
      when "not_in"       then !Array(target).map(&:to_s).include?(field_value.to_s)
      else false
      end
    rescue => e
      Rails.logger.warn "Error evaluating condition: #{e.message}"
      false
    end

    def resolve_field(field)
      case field
      when "value"              then @card.value
      when "days_in_stage"      then @card.days_in_stage
      when "assigned_agent_id"  then @card.assigned_agent_id
      when "contact_name"       then @card.contact_name
      when "contact_phone"      then @card.contact_phone
      when "contact_email"      then @card.contact_email
      when "stage_type"         then @card.stage&.stage_type
      when "title"              then @card.title
      when "archived_at"        then @card.archived_at
      else
        @card.custom_fields&.fetch(field, nil)
      end
    end

    def safe_equals(a, b)
      a.to_s == b.to_s
    end

    def safe_numeric_compare(a, b, operator)
      return false if a.nil? || b.nil?
      a_num = a.is_a?(Numeric) ? a : a.to_s.to_f
      b_num = b.is_a?(Numeric) ? b : b.to_s.to_f
      a_num.send(operator, b_num)
    rescue
      false
    end

    def safe_string_op(a, method, b)
      return false if a.nil? || b.nil?
      a.to_s.send(method, b.to_s)
    rescue
      false
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
