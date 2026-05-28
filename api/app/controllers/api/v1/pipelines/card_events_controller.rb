module Api
  module V1
    module Pipelines
      class CardEventsController < ApplicationController
        before_action :require_workspace!
        before_action :set_pipeline
        before_action :set_card

        # GET /api/v1/pipelines/:pipeline_id/cards/:card_id/timeline
        def timeline
          authorize @card, :show?, policy_class: CardPolicy

          limit  = params.fetch(:limit, 200).to_i
          events = @card.card_events.includes(:user).chronological
          result = events.map { |e| event_payload(e) }
          result = merge_chatwoot_messages(result)
          result = result.sort_by { |e| e[:created_at] || Time.at(0) }.last(limit)

          render json: { data: result }
        end

        private

        def set_pipeline
          @pipeline = current_workspace.pipelines.find(params[:pipeline_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Pipeline não encontrado" }, status: :not_found
        end

        def set_card
          @card = @pipeline.cards.find(params[:card_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Card não encontrado" }, status: :not_found
        end

        def event_payload(event)
          {
            id:         event.id,
            event_type: event.event_type,
            payload:    event.payload,
            user:       event.user && { id: event.user.id, name: event.user.name },
            created_at: event.created_at,
            label:      human_label(event)
          }
        end

        def human_label(event)
          user_name = event.user&.name || "Sistema"
          case event.event_type
          when "card_created"
            "#{user_name} criou o card"
          when "card_updated"
            "#{user_name} atualizou o card"
          when "card_moved"
            from = event.payload["from_stage_name"]
            to   = event.payload["to_stage_name"]
            "#{user_name} moveu de #{from} → #{to}"
          when "card_archived"
            "#{user_name} arquivou o card"
          when "stage_changed"
            "#{user_name} alterou a etapa"
          when "note_added"
            "#{user_name} adicionou uma nota"
          when "chatwoot_message"
            subtype = event.payload["subtype"]
            if subtype == "status_changed"
              "Status alterado para #{event.payload['status']}"
            elsif event.payload["message_type"] == "outgoing"
              "Mensagem enviada"
            else
              "Mensagem recebida"
            end
          when "message_sent"
            "#{user_name} enviou uma mensagem"
          when "conversation_linked"
            "#{user_name} vinculou conversa ##{event.payload['chatwoot_conversation_id']}"
          when "conversation_unlinked"
            "#{user_name} desvinculou conversa"
          else
            event.event_type
          end
        end

        def merge_chatwoot_messages(existing_events)
          conv = @card.conversations.order(created_at: :desc).first
          return existing_events unless conv

          config = current_workspace.chatwoot_config
          return existing_events unless config

          known_ids = existing_events
                        .filter_map { |e| p = e[:payload] || {}; p["message_id"] || p["chatwoot_msg_id"] }
                        .map(&:to_i).to_set

          begin
            client   = ::Chatwoot::Client.new(config)
            raw      = client.messages(conv.chatwoot_conversation_id)
            messages = raw[:payload] || []

            messages.each do |msg|
              next if msg[:id].blank?
              next if known_ids.include?(msg[:id].to_i)
              next if msg[:content].blank?
              next if msg[:message_type].to_i > 1

              msg_type = msg[:message_type].to_i == 0 ? "incoming" : "outgoing"

              existing_events << {
                id:         "cw_#{msg[:id]}",
                event_type: "chatwoot_message",
                payload:    {
                  "subtype"         => "message",
                  "message_type"    => msg_type,
                  "content"         => msg[:content],
                  "sender_name"     => msg.dig(:sender, :name),
                  "conversation_id" => conv.chatwoot_conversation_id,
                  "chatwoot_msg_id" => msg[:id]
                },
                user:       nil,
                created_at: msg[:created_at] ? Time.at(msg[:created_at].to_i) : nil,
                label:      msg_type == "incoming" ? "Mensagem recebida" : "Mensagem enviada"
              }
            end
          rescue ::Chatwoot::Client::ApiError => e
            Rails.logger.warn "[Timeline] Chatwoot fetch failed: #{e.message}"
          end

          existing_events
        end
      end
    end
  end
end
