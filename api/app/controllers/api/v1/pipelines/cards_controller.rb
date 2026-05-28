module Api
  module V1
    module Pipelines
      class CardsController < ApplicationController
        before_action :require_workspace!
        before_action :set_pipeline
        before_action :set_card, only: [:show, :update, :destroy, :move, :archive]

        # GET /api/v1/pipelines/:pipeline_id/cards
        def index
          authorize Card.new(workspace: current_workspace, pipeline: @pipeline), :index?

          cards = @pipeline.cards.active.includes(:stage, :assigned_agent)
          cards = cards.in_stage(params[:stage_id])                        if params[:stage_id].present?
          cards = cards.where(assigned_agent_id: params[:agent_id])        if params[:agent_id].present?

          render json: { data: cards.ordered.map { |c| card_payload(c) } }
        end

        # GET /api/v1/pipelines/:pipeline_id/cards/:id
        def show
          authorize @card
          render json: { data: card_payload(@card, detailed: true) }
        end

        # POST /api/v1/pipelines/:pipeline_id/cards
        def create
          stage = @pipeline.stages.find(card_params[:stage_id])
          card  = @pipeline.cards.build(
            card_params.merge(workspace: current_workspace, stage: stage, stage_changed_at: Time.current)
          )
          authorize card

          if card.save
            CardEvent.create!(
              card: card, workspace: current_workspace,
              user_id: current_user.id, event_type: "card_created",
              payload: { title: card.title, stage_id: card.stage_id, value: card.value.to_f }
            )
            render json: { data: card_payload(card) }, status: :created
          else
            render_unprocessable(card)
          end
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Etapa não encontrada" }, status: :not_found
        end

        # PATCH /api/v1/pipelines/:pipeline_id/cards/:id
        def update
          authorize @card

          if @card.update(card_update_params)
            CardEvent.create!(
              card: @card, workspace: current_workspace,
              user_id: current_user.id, event_type: "card_updated",
              payload: { changes: @card.previous_changes.except("updated_at") }
            )
            render json: { data: card_payload(@card) }
          else
            render_unprocessable(@card)
          end
        end

        # DELETE /api/v1/pipelines/:pipeline_id/cards/:id
        def destroy
          authorize @card
          @card.destroy
          head :no_content
        end

        # POST /api/v1/pipelines/:pipeline_id/cards/:id/move
        def move
          authorize @card, :move?
          stage = @pipeline.stages.find(params.require(:stage_id))
          @card.move_to_stage!(stage, user: current_user, reason: params[:lost_reason])
          render json: { data: card_payload(@card) }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Etapa não encontrada" }, status: :not_found
        end

        # POST /api/v1/pipelines/:pipeline_id/cards/:id/archive
        def archive
          authorize @card, :archive?
          @card.archive!(user: current_user)
          head :no_content
        end

        private

        def set_pipeline
          @pipeline = current_workspace.pipelines.find(params[:pipeline_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Pipeline não encontrado" }, status: :not_found
        end

        def set_card
          @card = @pipeline.cards.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Card não encontrado" }, status: :not_found
        end

        def card_params
          params.require(:card).permit(
            :title, :value, :currency, :stage_id,
            :assigned_agent_id, :contact_name, :contact_phone, :contact_email,
            custom_fields: {}
          )
        end

        def card_update_params
          params.require(:card).permit(
            :title, :value, :currency,
            :assigned_agent_id, :contact_name, :contact_phone, :contact_email,
            custom_fields: {}
          )
        end

        def card_payload(card, detailed: false)
          payload = {
            id:                card.id,
            pipeline_id:       card.pipeline_id,
            stage_id:          card.stage_id,
            stage_name:        card.stage.name,
            stage_color:       card.stage.color,
            stage_type:        card.stage.stage_type,
            title:             card.title,
            value:             card.value.to_f,
            currency:          card.currency,
            contact_name:      card.contact_name,
            contact_phone:     card.contact_phone,
            contact_email:     card.contact_email,
            assigned_agent_id: card.assigned_agent_id,
            assigned_agent:    card.assigned_agent && { id: card.assigned_agent.id, name: card.assigned_agent.name },
            lost_reason:       card.lost_reason,
            days_in_stage:     card.days_in_stage,
            stage_changed_at:  card.stage_changed_at,
            archived_at:       card.archived_at,
            custom_fields:     card.custom_fields,
            created_at:        card.created_at,
            updated_at:        card.updated_at
          }
          payload[:events_count] = card.card_events.count if detailed
          payload
        end
      end
    end
  end
end
