module Api
  module V1
    module Pipelines
      class AutomationsController < ApplicationController
      before_action :require_workspace!
      before_action :set_pipeline
      before_action :set_automation, only: [:show, :update, :destroy, :toggle, :logs]

      def index
        authorize Automation.new(workspace: current_workspace, pipeline: @pipeline), :index?
        automations = @pipeline.automations.ordered
        render json: { data: automations.map { |a| automation_payload(a) } }
      end

      def show
        authorize @automation
        render json: { data: automation_payload(@automation, detailed: true) }
      end

      def create
        authorize Automation.new(workspace: current_workspace, pipeline: @pipeline), :create?
        automation = @pipeline.automations.build(automation_params)
        automation.workspace = current_workspace

        if automation.save
          render json: { data: automation_payload(automation) }, status: :created
        else
          render_unprocessable(automation)
        end
      end

      def update
        authorize @automation
        if @automation.update(automation_params)
          render json: { data: automation_payload(@automation) }
        else
          render_unprocessable(@automation)
        end
      end

      def destroy
        authorize @automation
        @automation.destroy
        head :no_content
      end

      def toggle
        authorize @automation, :update?
        @automation.update!(active: !@automation.active)
        render json: { data: { active: @automation.active } }
      end

      def logs
        authorize @automation, :show?
        logs = @automation.automation_logs.order(created_at: :desc).limit(50)
        render json: { data: logs.map { |log| log_payload(log) } }
      end

      def available_fields
        authorize Automation.new(workspace: current_workspace, pipeline: @pipeline), :index?
        
        fields = Automation::AVAILABLE_FIELDS.map do |field_name, field_config|
          {
            id: field_name,
            name: field_config[:label],
            type: field_config[:type],
            operators: operators_for_type(field_config[:type]),
            values: field_config[:values]
          }
        end

        # Add custom fields from workspace cards
        custom_fields = @pipeline.cards
          .where.not(custom_fields: {})
          .pluck(:custom_fields)
          .flat_map(&:keys).uniq.compact
        
        custom_fields.each do |field_name|
          fields << {
            id: field_name,
            name: "Custom: #{field_name}",
            type: "text",
            operators: %w[eq neq contains not_contains starts_with present blank in not_in]
          }
        end

        render json: { data: { fields: fields, operators: Automation::OPERATORS } }
      end

      private

      def set_pipeline
        @pipeline = current_workspace.pipelines.find(params[:pipeline_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Pipeline não encontrado" }, status: :not_found
      end

      def set_automation
        @automation = @pipeline.automations.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Automation não encontrada" }, status: :not_found
      end

      def automation_params
        permitted = params.require(:automation).permit(
          :name, :description, :trigger_type, :active, :position
        )
        # conditions and actions are arrays of hashes — extract directly from raw params
        raw = params.require(:automation)
        permitted[:trigger_config] = raw[:trigger_config].to_unsafe_h if raw[:trigger_config].present?
        permitted[:conditions]     = raw[:conditions].map(&:to_unsafe_h) if raw[:conditions].present?
        permitted[:actions]        = raw[:actions].map { |a| a.respond_to?(:to_unsafe_h) ? a.to_unsafe_h : a } if raw[:actions].present?
        permitted
      end

      def automation_payload(automation, detailed: false)
        payload = {
          id: automation.id,
          name: automation.name,
          description: automation.description,
          trigger_type: automation.trigger_type,
          trigger_config: automation.trigger_config,
          conditions: automation.conditions,
          actions: automation.actions,
          active: automation.active,
          position: automation.position,
          created_at: automation.created_at,
          updated_at: automation.updated_at
        }
        payload[:logs_count] = automation.automation_logs.count if detailed
        payload
      end

      def log_payload(log)
        {
          id: log.id,
          automation_id: log.automation_id,
          card_id: log.card_id,
          status: log.status,
          actions_executed: log.actions_executed,
          error_message: log.error_message,
          created_at: log.created_at
        }
      end

      def operators_for_type(type)
        case type
        when "number"
          %w[eq neq gt gte lt lte]
        when "text"
          %w[eq neq contains not_contains starts_with present blank in not_in]
        when "select"
          %w[eq neq in not_in]
        else
          Automation::OPERATORS
        end
      end
      end
    end
  end
end
