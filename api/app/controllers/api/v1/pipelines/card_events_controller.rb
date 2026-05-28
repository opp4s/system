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
          else
            event.event_type
          end
        end
      end
    end
  end
end
