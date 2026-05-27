module Funnels
  module Api
    class StagesController < BaseController
      before_action :set_funnel
      before_action :set_stage, only: %i[update destroy]

      def index
        stages = @funnel.stages.ordered
        render json: stages.map { |s| stage_json(s) }
      end

      def create
        stage = @funnel.stages.build(stage_params)
        if stage.save
          invalidate_stage_cache(stage)
          render json: stage_json(stage), status: :created
        else
          render json: { errors: stage.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @stage.update(stage_params)
          invalidate_stage_cache(@stage)
          render json: stage_json(@stage)
        else
          render json: { errors: @stage.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @stage.cards.active.any?
          render json: { error: 'Não é possível excluir etapa com cards ativos' }, status: :unprocessable_entity
          return
        end
        @stage.destroy
        invalidate_stage_cache(@stage)
        head :no_content
      end

      def reorder
        params.require(:stage_ids).each_with_index do |id, index|
          @funnel.stages.where(id: id).update_all(position: index)
        end
        render json: { success: true }
      end

      private

      def set_funnel
        @funnel = @account.funnels.find(params[:funnel_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil não encontrado' }, status: :not_found
      end

      def set_stage
        @stage = @funnel.stages.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Etapa não encontrada' }, status: :not_found
      end

      def stage_params
        params.require(:stage).permit(:name, :color, :position, :stage_type, :win_probability)
      end

      def stage_json(stage)
        {
          id: stage.id,
          funnel_id: stage.funnel_id,
          name: stage.name,
          color: stage.color,
          position: stage.position,
          stage_type: stage.stage_type,
          win_probability: stage.win_probability,
          cards_count: stage.cards.active.count,
          total_value: stage.cards.active.sum(:value).to_f
        }
      end

      def invalidate_stage_cache(stage)
        Rails.cache.delete("funnels:stage_counts:#{stage.id}")
      end
    end
  end
end
