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
          when "connection.update"
            handle_connection_update(instance_name, params.to_unsafe_h)
          when "qrcode.updated"
            Rails.logger.info "[Evolution] QR atualizado para #{instance_name}"
          end

          head :ok
        end

        private

        def handle_connection_update(instance_name, data)
          state = data.dig("data", "state")
          Rails.logger.info "[Evolution] Connection update: #{instance_name} → #{state}"

          return unless instance_name&.start_with?("zavy-")

          parts = instance_name.split("-")
          return unless parts.length >= 3

          workspace_id = parts[1].to_i
          return unless workspace_id > 0

          workspace = Workspace.find_by(id: workspace_id)
          return unless workspace

          wi = workspace.whatsapp_instances.find_by(instance_id: instance_name)
          return unless wi

          case state
          when "open"
            updates = { status: "connected" }
            # Captura número real do JID quando a instância foi criada sem phone
            wuid = data.dig("data", "wuid") || data.dig("data", "user", "id")
            if wuid.present? && wi.phone_number.blank?
              updates[:phone_number] = wuid.split("@").first
            end
            wi.update_columns(updates)
          when "close", "failed"
            wi.update_columns(status: "disconnected")
          end
        rescue => e
          Rails.logger.error "[Evolution] handle_connection_update error: #{e.message}"
        end
      end
    end
  end
end
