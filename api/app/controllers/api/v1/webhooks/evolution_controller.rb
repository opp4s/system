module Api
  module V1
    module Webhooks
      class EvolutionController < ApplicationController
        skip_before_action :authenticate_user!
        skip_before_action :resolve_current_workspace

        # POST /api/v1/webhooks/evolution
        def receive
          event = params[:event]
          instance_name = params[:instance]

          case event
          when "CONNECTION_UPDATE"
            handle_connection_update(instance_name, params.to_unsafe_h)
          when "QRCODE_UPDATED"
            # QR expirou — frontend deve fazer GET /whatsapp/status para novo QR
            Rails.logger.info "[Evolution] QR atualizado para #{instance_name}"
          end

          head :ok
        end

        private

        def handle_connection_update(instance_name, data)
          state = data.dig("data", "state")
          Rails.logger.info "[Evolution] Connection update: #{instance_name} → #{state}"

          # Extrai workspace_id do nome da instância: zavy-{workspace_id}-{phone}
          return unless instance_name&.start_with?("zavy-")

          parts = instance_name.split("-")
          return unless parts.length >= 3

          workspace_id = parts[1].to_i
          return unless workspace_id > 0

          workspace = Workspace.find_by(id: workspace_id)
          return unless workspace

          config = workspace.chatwoot_config
          return unless config

          if state == "open"
            new_settings = (config.settings || {}).merge("whatsapp_connected" => true)
            config.update_columns(settings: new_settings)
          elsif state.in?(%w[close failed])
            new_settings = (config.settings || {}).merge("whatsapp_connected" => false)
            config.update_columns(settings: new_settings)
          end
        rescue => e
          Rails.logger.error "[Evolution] handle_connection_update error: #{e.message}"
        end
      end
    end
  end
end
