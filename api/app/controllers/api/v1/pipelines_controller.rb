module Api
  module V1
    class PipelinesController < ApplicationController
      before_action :require_workspace!
      before_action :set_pipeline, only: [:show, :update, :destroy]

      # GET /api/v1/pipelines
      def index
        pipelines = policy_scope(Pipeline).ordered.includes(:stages, :cards)
        render json: { data: pipelines.map { |p| pipeline_payload(p) } }
      end

      # GET /api/v1/pipelines/:id
      def show
        authorize @pipeline
        render json: { data: pipeline_payload(@pipeline, include_stages: true) }
      end

      # POST /api/v1/pipelines
      def create
        pipeline = current_workspace.pipelines.build(pipeline_params)
        authorize pipeline

        if pipeline.save
          pipeline.provision_default_stages! if pipeline.stages.empty?
          pipeline.reload
          render json: { data: pipeline_payload(pipeline, include_stages: true) }, status: :created
        else
          render_unprocessable(pipeline)
        end
      end

      # PATCH /api/v1/pipelines/:id
      def update
        authorize @pipeline

        if @pipeline.update(pipeline_params)
          render json: { data: pipeline_payload(@pipeline, include_stages: true) }
        else
          render_unprocessable(@pipeline)
        end
      end

      # DELETE /api/v1/pipelines/:id
      def destroy
        authorize @pipeline

        if @pipeline.cards.active.exists?
          return render json: { error: "Não é possível excluir pipeline com cards ativos" },
                        status: :unprocessable_entity
        end

        @pipeline.destroy
        head :no_content
      end

      # POST /api/v1/pipelines/reorder
      def reorder
        authorize Pipeline.new(workspace: current_workspace), :reorder?
        Pipeline.reorder!(params.require(:pipeline_ids), workspace: current_workspace)
        render json: { data: { message: "Pipelines reordenados" } }
      end

      private

      def set_pipeline
        @pipeline = current_workspace.pipelines.find(params[:id])
      end

      def pipeline_params
        params.require(:pipeline).permit(:name, :description, :color, :position, :is_default)
      end

      def pipeline_payload(pipeline, include_stages: false)
        payload = {
          id:           pipeline.id,
          name:         pipeline.name,
          description:  pipeline.description,
          color:        pipeline.color,
          position:     pipeline.position,
          is_default:   pipeline.is_default,
          cards_count:  pipeline.cards.active.size,
          created_at:   pipeline.created_at,
          updated_at:   pipeline.updated_at
        }
        payload[:stages] = pipeline.stages.ordered.map { |s| brief_stage_payload(s) } if include_stages
        payload
      end

      def brief_stage_payload(stage)
        {
          id:              stage.id,
          name:            stage.name,
          color:           stage.color,
          position:        stage.position,
          stage_type:      stage.stage_type,
          win_probability: stage.win_probability,
          cards_count:     cached_stage_count(stage)
        }
      end

      def cached_stage_count(stage)
        Rails.cache.fetch("stage_cards_count_#{stage.id}", expires_in: 30.seconds) do
          stage.cards.active.count
        end
      end
    end
  end
end
