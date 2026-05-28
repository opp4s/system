module Automations
  class TriggerJob < ApplicationJob
    queue_as :default

    def perform(card_id:, trigger_type:, context: {})
      card = Card.find(card_id)
      Automations::Executor.new(card, trigger_type, context).run!
    rescue StandardError => e
      Rails.logger.error "AutomationsTriggerJob failed: #{e.message}"
    end
  end
end
