module Automations
  class SchedulerJob < ApplicationJob
    queue_as :default

    def perform
      Automation.active.for_trigger("time_in_stage").find_each do |automation|
        days_threshold = automation.trigger_config["days"].to_i
        stage_id       = automation.trigger_config["stage_id"].to_i
        next if stage_id <= 0  # days >= 0 é válido (0 = qualquer tempo na stage)

        cutoff = days_threshold.days.ago

        Card.active
            .where(stage_id: stage_id)
            .where("stage_changed_at < ?", cutoff)
            .find_each do |card|
          next if recently_ran?(automation, card)
          Automations::Executor.new(card, "time_in_stage").run!
        end
      end
    end

    private

    def recently_ran?(automation, card)
      AutomationLog.exists?(
        automation_id: automation.id,
        card_id:       card.id,
        created_at:    24.hours.ago..
      )
    end
  end
end
