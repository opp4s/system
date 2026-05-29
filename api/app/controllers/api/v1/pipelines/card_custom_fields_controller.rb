module Api
  module V1
    module Pipelines
      class CardCustomFieldsController < ApplicationController
        before_action :require_workspace!
        before_action :set_pipeline
        before_action :set_card

        # GET /api/v1/pipelines/:pipeline_id/cards/:card_id/custom_fields
        def show
          authorize @card, :show?, policy_class: CardPolicy
          render json: { data: @card.custom_fields }
        end

        # PATCH /api/v1/pipelines/:pipeline_id/cards/:card_id/custom_fields
        # Merge semântico: envia apenas as chaves que quer alterar.
        # Para remover uma chave, envie-a com valor null.
        def update
          authorize @card, :update?, policy_class: CardPolicy

          merged = @card.custom_fields.merge(custom_fields_params)
          merged.delete_if { |_, v| v.nil? }

          if @card.update(custom_fields: merged)
            CardEvent.create!(
              card:       @card,
              workspace:  current_workspace,
              user_id:    current_user.id,
              event_type: "card_updated",
              payload:    { changes: { custom_fields: [nil, merged] } }
            )
            render json: { data: @card.custom_fields }
          else
            render_unprocessable(@card)
          end
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

        def custom_fields_params
          params.require(:custom_fields).permit!.to_h
        end
      end
    end
  end
end
