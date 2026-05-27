module Funnels
  # Centraliza todos os broadcasts ActionCable do plugin.
  # Envia para dois streams: funnel_{id} (todos os viewers do quadro)
  # e funnel_card_{id} (quem está com o card aberto).
  module Broadcaster
    module_function

    def card_event(card, event_name, extra: {})
      payload = card_payload(card).merge(extra).merge(event: event_name)

      ActionCable.server.broadcast("funnel_#{card.funnel_id}", payload)
      ActionCable.server.broadcast("funnel_card_#{card.id}",  payload)

      Rails.logger.debug "[funnels] broadcast #{event_name} → funnel_#{card.funnel_id} + funnel_card_#{card.id}"
    end

    def stage_updated(stage)
      payload = {
        event:       'stage_updated',
        stage_id:    stage.id,
        funnel_id:   stage.funnel_id,
        cards_count: stage.cards.active.count,
        total_value: stage.cards.active.sum(:value).to_f,
      }
      ActionCable.server.broadcast("funnel_#{stage.funnel_id}", payload)
    end

    # ── Serialização canônica ─────────────────────────────────────────────────

    def card_payload(card)
      primary_cc   = card.card_conversations.find { |cc| cc.is_primary? }
      conversation = primary_cc&.conversation
      contact      = conversation&.contact

      {
        card: {
          id:                      card.id,
          title:                   card.title,
          funnel_id:               card.funnel_id,
          stage_id:                card.funnel_stage_id,
          value:                   card.value.to_f,
          currency:                card.currency,
          days_in_stage:           card.days_in_stage,
          archived_at:             card.archived_at,
          primary_conversation_id: primary_cc&.conversation_id,
          contact_name:            contact&.name,
          contact_phone:           contact&.phone_number,
          labels:                  conversation&.labels || [],
          assigned_agent:          serialize_agent(card.assigned_agent),
          assigned_team:           serialize_team(card.assigned_team),
          created_at:              card.created_at,
          updated_at:              card.updated_at,
        }
      }
    end

    def serialize_agent(agent)
      return nil unless agent
      { id: agent.id, name: agent.name, avatar: agent.avatar_url }
    end

    def serialize_team(team)
      return nil unless team
      { id: team.id, name: team.name }
    end
  end
end
