module Api
  module V1
    class CustomFieldsController < ApplicationController
      before_action :require_workspace!
      before_action :set_definition, only: [:show, :update, :destroy]

      # GET /api/v1/custom_fields?pipeline_id=X
      def index
        scope = current_workspace.custom_field_definitions.ordered
        scope = scope.for_pipeline(params[:pipeline_id]) if params[:pipeline_id].present?
        render json: { data: scope.map { |d| definition_payload(d) } }
      end

      # GET /api/v1/custom_fields/:id
      def show
        render json: { data: definition_payload(@definition) }
      end

      # POST /api/v1/custom_fields
      def create
        defn = current_workspace.custom_field_definitions.build(definition_params)
        authorize defn

        if defn.save
          render json: { data: definition_payload(defn) }, status: :created
        else
          render_unprocessable(defn)
        end
      end

      # PATCH /api/v1/custom_fields/:id
      def update
        authorize @definition

        if @definition.update(definition_params)
          render json: { data: definition_payload(@definition) }
        else
          render_unprocessable(@definition)
        end
      end

      # DELETE /api/v1/custom_fields/:id
      def destroy
        authorize @definition
        @definition.destroy
        head :no_content
      end

      private

      def set_definition
        @definition = current_workspace.custom_field_definitions.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Campo não encontrado" }, status: :not_found
      end

      def definition_params
        p = params.require(:custom_field).permit(
          :name, :field_type, :pipeline_id, :position, :tab_name, :required
        ).to_h
        p[:options] = params[:custom_field][:options].to_unsafe_h if params.dig(:custom_field, :options).present?
        p
      end

      def definition_payload(defn)
        {
          id:          defn.id,
          workspace_id: defn.workspace_id,
          pipeline_id: defn.pipeline_id,
          name:        defn.name,
          field_type:  defn.field_type,
          options:     defn.options,
          position:    defn.position,
          tab_name:    defn.tab_name,
          required:    defn.required,
          created_at:  defn.created_at,
          updated_at:  defn.updated_at
        }
      end
    end
  end
end
