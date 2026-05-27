module Funnels
  module Api
    class FunnelsController < BaseController
      before_action :set_funnel, only: %i[show update destroy analytics]

      def index
        funnels = @account.funnels.ordered.includes(:stages)
        render json: funnels.map { |f| funnel_json(f) }
      end

      def show
        render json: funnel_json(@funnel, include_stages: true)
      end

      def create
        funnel = @account.funnels.build(funnel_params)
        if funnel.save
          render json: funnel_json(funnel, include_stages: true), status: :created
        else
          render json: { errors: funnel.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @funnel.update(funnel_params)
          render json: funnel_json(@funnel, include_stages: true)
        else
          render json: { errors: @funnel.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @funnel.destroy
        head :no_content
      end

      def analytics

      def reorder
        ids = params.require(:funnel_ids)
        ids.each_with_index do |id, index|
          @account.funnels.where(id: id).update_all(position: index)
        end
        render json: @account.funnels.ordered.map { |f| funnel_json(f) }
      end
        cache_key = "funnels:analytics:#{@funnel.id}:#{Date.today}"
        data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
          build_analytics(@funnel)
        end
        render json: data
      end

      private

      def set_funnel
        @funnel = @account.funnels.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil não encontrado' }, status: :not_found
      end

      def funnel_params
        params.require(:funnel).permit(:name, :description, :color, :position, :is_default)
      end

      def funnel_json(funnel, include_stages: false)
        result = {
          id: funnel.id,
          name: funnel.name,
          description: funnel.description,
          color: funnel.color,
          position: funnel.position,
          is_default: funnel.is_default,
          cards_count: funnel.cards.active.count,
          created_at: funnel.created_at
        }
        if include_stages
          result[:stages] = funnel.stages.ordered.map { |s| stage_json(s) }
        end
        result
      end

      def stage_json(stage)
        cache_key = "funnels:stage_counts:#{stage.id}"
        counts = Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
          cards = stage.cards.active
          { count: cards.count, total_value: cards.sum(:value).to_f }
        end
        {
          id: stage.id,
          funnel_id: stage.funnel_id,
          name: stage.name,
          color: stage.color,
          position: stage.position,
          stage_type: stage.stage_type,
          win_probability: stage.win_probability,
          cards_count: counts[:count],
          total_value: counts[:total_value]
        }
      end

      def build_analytics(funnel)
        stages = funnel.stages.ordered

        # Uma query por agregado — evita N+1
        active_cards = funnel.cards.active

        counts_by_stage = active_cards.group(:funnel_stage_id).count
        values_by_stage = active_cards.group(:funnel_stage_id).sum(:value)
        avg_days_by_stage = active_cards
                              .where.not(stage_changed_at: nil)
                              .group(:funnel_stage_id)
                              .average(Arel.sql("EXTRACT(epoch FROM (NOW() - stage_changed_at)) / 86400"))

        stage_ids_by_type = stages.each_with_object({ 'won' => [], 'lost' => [] }) do |s, h|
          h[s.stage_type] << s.id if h.key?(s.stage_type)
        end

        {
          funnel_id:   funnel.id,
          total_cards: active_cards.count,
          total_value: active_cards.sum(:value).to_f,
          won_cards:   counts_by_stage.slice(*stage_ids_by_type['won']).values.sum,
          lost_cards:  counts_by_stage.slice(*stage_ids_by_type['lost']).values.sum,
          conversion_rate: begin
            total = active_cards.count
            won   = counts_by_stage.slice(*stage_ids_by_type['won']).values.sum
            total > 0 ? (won.to_f / total * 100).round(1) : 0.0
          end,
          stages: stages.map do |stage|
            {
              stage_id:         stage.id,
              stage_name:       stage.name,
              stage_type:       stage.stage_type,
              cards_count:      counts_by_stage[stage.id] || 0,
              total_value:      (values_by_stage[stage.id] || 0).to_f,
              avg_days_in_stage: (avg_days_by_stage[stage.id] || 0).to_f.round(1)
            }
          end
        }
      end
    end
  end
end
