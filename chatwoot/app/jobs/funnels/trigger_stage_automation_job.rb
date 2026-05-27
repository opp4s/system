module Funnels
  class TriggerStageAutomationJob < ApplicationJob
    queue_as :default

    # card_id, stage_id, event: 'on_enter' | 'on_leave', user_id (optional)
    def perform(card_id:, stage_id:, event:, user_id: nil)
      card  = Funnels::Card.find_by(id: card_id)
      stage = Funnels::Stage.find_by(id: stage_id)
      return unless card && stage

      automations = stage.stage_automations.active.where(trigger_event: event).ordered
      return if automations.empty?

      user = User.find_by(id: user_id)

      automations.each do |automation|
        run_automation(automation, card, user)
      rescue StandardError => e
        Rails.logger.error "[funnels] automation #{automation.id} failed: #{e.message}"
      end
    end

    private

    def run_automation(automation, card, user)
      case automation.automation_type
      when 'webhook'  then fire_webhook(automation, card)
      when 'message'  then send_message(automation, card)
      when 'task'     then create_task(automation, card, user)
      end
    end

    def fire_webhook(automation, card)
      cfg = automation.config.with_indifferent_access
      url = cfg[:url]
      return unless url.present?

      method  = (cfg[:method] || 'POST').upcase
      headers = (cfg[:headers] || {}).merge('Content-Type' => 'application/json')
      body    = cfg[:include_card] ? { card: Funnels::Broadcaster.card_payload(card)[:card] }.to_json : '{}'

      conn = Faraday.new(url: url, headers: headers) do |f|
        f.options.timeout = 10
        f.adapter Faraday.default_adapter
      end

      method == 'GET' ? conn.get : conn.post('', body)

      card.record_event('note_added', payload: {
        note: "Webhook disparado: #{automation.automation_type} (#{url})"
      })
    end

    def send_message(automation, card)
      cfg = automation.config.with_indifferent_access
      template = cfg[:template]
      return unless template.present?

      primary_conv = card.primary_conversation
      return unless primary_conv

      Messages::MessageBuilder.new(nil, primary_conv, {
        message: { content: template },
        message_type: :outgoing,
        private: false
      }).perform

      card.record_event('note_added', payload: { note: "Mensagem automática enviada: #{template.truncate(60)}" })
    end

    def create_task(automation, card, user)
      cfg = automation.config.with_indifferent_access
      title = cfg[:title] || 'Tarefa automática'
      card.record_event('note_added', user: user, payload: {
        note: "Tarefa criada automaticamente: #{title}"
      })
    end
  end
end
