module Api
  module V1
    class DashboardController < ApplicationController
      before_action :require_workspace!
      CACHE_TTL = 5.minutes

      # GET /api/v1/dashboard
      def index
        period     = parse_period(params[:period])
        pipeline_id = params[:pipeline_id]

        data = Rails.cache.fetch(cache_key("dashboard", period, pipeline_id), expires_in: CACHE_TTL) do
          compute_dashboard(period, pipeline_id)
        end

        render json: { data: data }
      end

      # GET /api/v1/dashboard/funnel
      def funnel
        period      = parse_period(params[:period])
        pipeline_id = params[:pipeline_id]

        data = Rails.cache.fetch(cache_key("funnel", period, pipeline_id), expires_in: CACHE_TTL) do
          compute_funnel(period, pipeline_id)
        end

        render json: { data: data }
      end

      # GET /api/v1/dashboard/agents
      def agents
        period      = parse_period(params[:period])
        pipeline_id = params[:pipeline_id]

        data = Rails.cache.fetch(cache_key("agents", period, pipeline_id), expires_in: CACHE_TTL) do
          compute_agents(period, pipeline_id)
        end

        render json: { data: data }
      end

      private

      def parse_period(param)
        case param
        when "last_7_days"  then 7.days.ago.beginning_of_day
        when "last_90_days" then 90.days.ago.beginning_of_day
        when "all_time"     then nil
        else 30.days.ago.beginning_of_day  # default: last_30_days
        end
      end

      def cache_key(type, period, pipeline_id)
        "dashboard/ws#{current_workspace.id}/#{type}/#{period&.to_i || 'all'}/pl#{pipeline_id || 'all'}"
      end

      def base_cards(pipeline_id = nil)
        scope = current_workspace.cards
        scope = scope.joins(:pipeline).where(pipeline_id: pipeline_id) if pipeline_id.present?
        scope
      end

      def won_stage_ids(pipeline_id = nil)
        stages = current_workspace.pipelines
        stages = stages.where(id: pipeline_id) if pipeline_id.present?
        Stage.where(pipeline: stages).won.pluck(:id)
      end

      def lost_stage_ids(pipeline_id = nil)
        stages = current_workspace.pipelines
        stages = stages.where(id: pipeline_id) if pipeline_id.present?
        Stage.where(pipeline: stages).lost.pluck(:id)
      end

      # ── Dashboard KPIs ─────────────────────────────────────────────────────

      def compute_dashboard(period, pipeline_id)
        cards = base_cards(pipeline_id)
        won_ids  = won_stage_ids(pipeline_id)
        lost_ids = lost_stage_ids(pipeline_id)

        active_cards = cards.active
        total_value  = active_cards.sum(:value).to_f

        period_scope  = period ? cards.where("cards.stage_changed_at >= ?", period) : cards
        won_cards     = period_scope.where(stage_id: won_ids).where.not(archived_at: nil).or(
                          period_scope.where(stage_id: won_ids).active
                        )
        won_this_period = cards.active.where(stage_id: won_ids)
        won_this_period = won_this_period.where("stage_changed_at >= ?", period) if period

        lost_this_period = cards.active.where(stage_id: lost_ids)
        lost_this_period = lost_this_period.where("stage_changed_at >= ?", period) if period

        won_count  = won_this_period.count
        lost_count = lost_this_period.count
        won_value  = won_this_period.sum(:value).to_f

        total_decided  = won_count + lost_count
        conversion     = total_decided > 0 ? (won_count.to_f / total_decided * 100).round(1) : 0

        # avg days to close: from created_at to stage_changed_at for won cards
        avg_days = if won_this_period.count > 0
          won_this_period.average(
            Arel.sql("EXTRACT(EPOCH FROM (stage_changed_at - created_at)) / 86400")
          )&.round(1).to_f
        else
          0
        end

        {
          kpis: {
            total_cards_active:    active_cards.count,
            total_value:           total_value,
            won_this_period:       won_count,
            won_value_this_period: won_value,
            lost_this_period:      lost_count,
            conversion_rate:       conversion,
            avg_days_to_close:     avg_days,
            period:                params[:period] || "last_30_days"
          },
          pipeline_summary: pipeline_summary(pipeline_id),
          recent_activity:  recent_activity
        }
      end

      def pipeline_summary(pipeline_id)
        pipelines = current_workspace.pipelines.includes(stages: :cards)
        pipelines = pipelines.where(id: pipeline_id) if pipeline_id.present?

        pipelines.map do |pipeline|
          cards_by_stage = pipeline.stages.map do |stage|
            active = stage.cards.active
            {
              stage_id:   stage.id,
              stage_name: stage.name,
              stage_type: stage.stage_type,
              count:      active.count,
              value:      active.sum(:value).to_f
            }
          end
          {
            pipeline_id:    pipeline.id,
            name:           pipeline.name,
            total_cards:    pipeline.cards.active.count,
            total_value:    pipeline.cards.active.sum(:value).to_f,
            cards_by_stage: cards_by_stage
          }
        end
      end

      def recent_activity
        CardEvent.where(workspace: current_workspace)
                 .where(event_type: %w[card_created card_moved card_archived])
                 .order(created_at: :desc)
                 .limit(10)
                 .includes(:card)
                 .map do |event|
          {
            type:       event.event_type,
            card_id:    event.card_id,
            card_title: event.card&.title,
            payload:    event.payload.slice("from_stage_name", "to_stage_name"),
            timestamp:  event.created_at
          }
        end
      end

      # ── Funnel ──────────────────────────────────────────────────────────────

      def compute_funnel(period, pipeline_id)
        pipelines = current_workspace.pipelines
        pipelines = pipelines.where(id: pipeline_id) if pipeline_id.present?

        events = CardEvent.where(workspace: current_workspace, event_type: "card_moved")
        events = events.where("card_events.created_at >= ?", period) if period
        events = events.joins(card: :pipeline).where(cards: { pipeline_id: pipelines.pluck(:id) }) if pipeline_id.present?

        # Count cards that "entered" each stage via card_moved (to_stage_id)
        entered_by_stage  = events.group("payload->>'to_stage_id'").count
        # Count cards that "exited" each stage (from_stage_id)
        exited_by_stage   = events.group("payload->>'from_stage_id'").count

        # Also count card_created events per stage
        created_events = CardEvent.where(workspace: current_workspace, event_type: "card_created")
        created_events = created_events.where("card_events.created_at >= ?", period) if period
        created_by_stage = created_events.joins(:card).group("cards.stage_id").count

        stages = Stage.joins(:pipeline).where(pipelines: { workspace_id: current_workspace.id })
        stages = stages.where(pipelines: { id: pipeline_id }) if pipeline_id.present?
        stages = stages.order("pipelines.id, stages.position")

        stage_data = stages.map do |stage|
          entered = entered_by_stage[stage.id.to_s].to_i + created_by_stage[stage.id].to_i
          exited  = exited_by_stage[stage.id.to_s].to_i
          conv    = entered > 0 ? ((entered - exited).to_f / entered * 100).round(1) : 0
          {
            stage_id:   stage.id,
            name:       stage.name,
            stage_type: stage.stage_type,
            entered:    entered,
            exited:     exited,
            retained:   [entered - exited, 0].max,
            conversion: conv
          }
        end

        total_entered = stage_data.sum { |s| s[:entered] }
        won_stages    = stage_data.select { |s| s[:stage_type] == "won" }
        total_won     = won_stages.sum { |s| s[:entered] }
        overall = total_entered > 0 ? (total_won.to_f / total_entered * 100).round(1) : 0

        { stages: stage_data, overall_conversion: overall, period: params[:period] || "last_30_days" }
      end

      # ── Agents ──────────────────────────────────────────────────────────────

      def compute_agents(period, pipeline_id)
        won_ids = won_stage_ids(pipeline_id)
        return [] if won_ids.empty?

        cards = current_workspace.cards.active.where(stage_id: won_ids).where.not(assigned_agent_id: nil)
        cards = cards.where(pipeline_id: pipeline_id) if pipeline_id.present?
        cards = cards.where("stage_changed_at >= ?", period) if period

        agents_data = cards.group(:assigned_agent_id).select(
          :assigned_agent_id,
          "COUNT(*) AS cards_won",
          "COALESCE(SUM(value), 0) AS value_won",
          "ROUND(AVG(EXTRACT(EPOCH FROM (stage_changed_at - created_at)) / 86400)::numeric, 1) AS avg_days"
        ).map do |row|
          user = User.find_by(id: row.assigned_agent_id)
          {
            agent_id:  row.assigned_agent_id,
            name:      user&.name || "Agente ##{row.assigned_agent_id}",
            email:     user&.email,
            cards_won: row.cards_won.to_i,
            value_won: row.value_won.to_f,
            avg_days:  row.avg_days.to_f
          }
        end

        agents_data.sort_by { |a| -a[:cards_won] }
      end
    end
  end
end
