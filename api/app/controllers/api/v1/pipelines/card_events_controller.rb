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

          events = @card.card_events
                        .includes(:user)
                        .reverse_chronological
                        .limit(params.fetch(:limit, 100).to_i)

          render json: { data: events.map { |e| event_payload(e) } }
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
          payload_data = event.payload || {}
          if event.event_type == "chatwoot_message" || event.event_type == "message_sent"
            cw_id = payload_data["chatwoot_msg_id"] || payload_data["message_id"] || payload_data["chatwoot_message_id"]
            if cw_id.present?
              msg = Message.find_by(chatwoot_message_id: cw_id.to_s)
              if msg && msg.metadata.present?
                payload_data = payload_data.merge(
                  "transcription" => msg.metadata["transcription"],
                  "metadata" => (payload_data["metadata"] || {}).merge(msg.metadata)
                )
              end
            end
          end
          {
            id:         event.id,
            event_type: event.event_type,
            payload:    payload_data,
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
          when "automation_message_sent"
            "Mensagem automática enviada"
          when "automation_moved"
            "Automação moveu para #{event.payload['to_stage_name']}"
          when "automation_assigned"
            "Automação atribuiu agente"
          when "automation_field_updated"
            "Automação atualizou campo"
          when "task_created"
            "Tarefa criada: #{event.payload['title']}"
          else
            event.event_type
          end
        end
      end
    end
  end
end
