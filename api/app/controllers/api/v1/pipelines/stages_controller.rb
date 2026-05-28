module Api
  module V1
    module Pipelines
      class StagesController < ApplicationController
        before_action :require_workspace!
        before_action :set_pipeline
        before_action :set_stage, only: [:update, :destroy]

        # GET /api/v1/pipelines/:pipeline_id/stages
        def index
          authorize @pipeline, :show?, policy_class: PipelinePolicy
          stages = @pipeline.stages.ordered
          render json: { data: stages.map { |s| stage_payload(s) } }
        end

        # POST /api/v1/pipelines/:pipeline_id/stages
        def create
          stage = @pipeline.stages.build(stage_params)
          authorize stage

          if stage.save
            render json: { data: stage_payload(stage) }, status: :created
          else
            render_unprocessable(stage)
          end
        end

        # PATCH /api/v1/pipelines/:pipeline_id/stages/:id
        def update
          authorize @stage

          if @stage.update(stage_params)
            render json: { data: stage_payload(@stage) }
          else
            render_unprocessable(@stage)
          end
        end

        # DELETE /api/v1/pipelines/:pipeline_id/stages/:id
        def destroy
          authorize @stage

          if @stage.cards.active.exists?
            return render json: { error: "Não é possível excluir etapa com cards ativos" },
                          status: :unprocessable_entity
          end

          @stage.destroy
          head :no_content
        end

        # POST /api/v1/pipelines/:pipeline_id/stages/reorder
        def reorder
          authorize Stage.new(pipeline: @pipeline), :reorder?
          Stage.reorder!(params.require(:stage_ids), pipeline: @pipeline)
          render json: { data: { message: "Etapas reordenadas" } }
        end

        private

        def set_pipeline
          @pipeline = current_workspace.pipelines.find(params[:pipeline_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Pipeline não encontrado" }, status: :not_found
        end

        def set_stage
          @stage = @pipeline.stages.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Etapa não encontrada" }, status: :not_found
        end

        def stage_params
          params.require(:stage).permit(
            :name, :color, :position, :stage_type, :win_probability,
            loss_reasons: []
          )
        end

        def stage_payload(stage)
          {
            id:              stage.id,
            pipeline_id:     stage.pipeline_id,
            name:            stage.name,
            color:           stage.color,
            position:        stage.position,
            stage_type:      stage.stage_type,
            win_probability: stage.win_probability,
            loss_reasons:    stage.loss_reasons,
            cards_count:     stage.cards.active.size,
            created_at:      stage.created_at,
            updated_at:      stage.updated_at
          }
        end
      end
    end
  end
end
