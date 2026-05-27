module Funnels
  module Api
    class StageAutomationsController < BaseController
      before_action :set_funnel
      before_action :set_stage
      before_action :set_automation, only: %i[update destroy]

      def index
        render json: @stage.stage_automations.ordered.map { |a| automation_json(a) }
      end

      def create
        automation = @stage.stage_automations.build(
          automation_params.merge(account_id: @account.id)
        )
        if automation.save
          render json: automation_json(automation), status: :created
        else
          render json: { errors: automation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @automation.update(automation_params)
          render json: automation_json(@automation)
        else
          render json: { errors: @automation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @automation.destroy
        head :no_content
      end

      private

      def set_funnel
        @funnel = @account.funnels.find(params[:funnel_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil não encontrado' }, status: :not_found
      end

      def set_stage
        @stage = @funnel.stages.find(params[:stage_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Etapa não encontrada' }, status: :not_found
      end

      def set_automation
        @automation = @stage.stage_automations.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Automação não encontrada' }, status: :not_found
      end

      def automation_params
        params.require(:automation).permit(
          :automation_type, :trigger_event, :active, :position,
          config: {}
        )
      end

      def automation_json(a)
        {
          id:               a.id,
          stage_id:         a.funnel_stage_id,
          automation_type:  a.automation_type,
          trigger_event:    a.trigger_event,
          config:           a.config,
          active:           a.active,
          position:         a.position,
          created_at:       a.created_at
        }
      end
    end
  end
end
