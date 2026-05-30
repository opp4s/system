module Api
  module V1
    module Whatsapp
      class ConnectionsController < ApplicationController
        before_action :require_workspace!

        # POST /api/v1/whatsapp/connect
        def connect
          raw_phone = params[:phone_number].to_s.gsub(/\D/, "")
          phone         = raw_phone.length >= 10 ? raw_phone : nil
          instance_name = phone \
            ? "zavy-#{current_workspace.id}-#{phone}" \
            : "zavy-#{current_workspace.id}-#{SecureRandom.uuid}"

          evo_client = ::Whatsapp::EvolutionClient.new
          state      = evo_client.connection_state(instance_name)

          if state == "open"
            wi = current_workspace.whatsapp_instances.find_or_initialize_by(instance_id: instance_name)
            wi.update!(phone_number: phone, status: "connected")
            return render json: { data: instance_payload(wi) }
          end

          evo_client.create_instance(instance_name, workspace_id: current_workspace.id) if state == "not_found"

          result = if params[:method] == "pairing" && phone
            evo_client.get_pairing_code(instance_name, phone)
          else
            evo_client.get_qr(instance_name)
          end

          wi = current_workspace.whatsapp_instances.find_or_initialize_by(instance_id: instance_name)
          wi.phone_number    = phone
          wi.status          = "qr_pending"
          wi.chatwoot_inbox_id ||= fetch_chatwoot_inbox_id(instance_name)
          wi.save!

          auto_configure_chatwoot

          render json: {
            data: instance_payload(wi).merge(
              qr_code_base64: result[:qr_base64],
              pairing_code:   result[:pairing_code],
              expires_at:     result[:expires_at]
            )
          }
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro na Evolution API: #{e.message}" }, status: :unprocessable_entity
        end

        # GET /api/v1/whatsapp/status
        def status
          instances  = current_workspace.whatsapp_instances.includes(:pipeline).order(:created_at)
          evo_client = ::Whatsapp::EvolutionClient.new

          result = instances.map do |wi|
            real_status = evolution_status(evo_client, wi.instance_id)
            if real_status && real_status != wi.status
              wi.update_columns(status: real_status)
              wi.status = real_status
            end
            instance_payload(wi)
          end

          render json: { data: { instances: result } }
        end

        # PATCH /api/v1/whatsapp/instances/:instance_id
        def update
          wi = current_workspace.whatsapp_instances.find_by(instance_id: params[:instance_id])
          return render json: { error: "Instância não encontrada" }, status: :not_found unless wi

          if wi.update(instance_update_params)
            wi.reload
            render json: { data: instance_payload(wi) }
          else
            render json: { errors: wi.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/whatsapp/disconnect
        def disconnect
          instance_name = params.require(:instance_id)
          wi = current_workspace.whatsapp_instances.find_by(instance_id: instance_name)

          unless wi
            return render json: { data: { disconnected: true, message: "Instância não encontrada" } }
          end

          ::Whatsapp::EvolutionClient.new.logout_instance(instance_name)
          wi.update_columns(status: "disconnected")

          render json: { data: { disconnected: true, instance_id: instance_name } }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        # DELETE /api/v1/whatsapp/destroy
        def destroy
          instance_name = params.require(:instance_id)
          wi = current_workspace.whatsapp_instances.find_by(instance_id: instance_name)

          unless wi
            return render json: { data: { deleted: true, message: "Instância não encontrada" } }
          end

          ::Whatsapp::EvolutionClient.new.delete_instance(instance_name)

          begin
            cw = ::Chatwoot::Client.from_env
            inbox_id = wi.chatwoot_inbox_id ||
                       cw.find_inbox_by_name(instance_name)&.then { |i| i[:id] || i["id"] }
            cw.delete_inbox(inbox_id) if inbox_id
          rescue => e
            Rails.logger.warn "[WhatsApp] Falha ao deletar inbox Chatwoot para #{instance_name}: #{e.message}"
          end

          wi.destroy!

          render json: { data: { deleted: true, instance_id: instance_name } }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        private

        def instance_update_params
          params.require(:instance).permit(:name, :pipeline_id)
        end

        def instance_payload(wi)
          {
            instance_id:       wi.instance_id,
            name:              wi.name,
            phone:             wi.phone_number.presence,
            status:            wi.status,
            pipeline_id:       wi.pipeline_id,
            pipeline:          wi.pipeline ? { id: wi.pipeline.id, name: wi.pipeline.name } : nil,
            chatwoot_inbox_id: wi.chatwoot_inbox_id,
            created_at:        wi.created_at
          }
        end

        def fetch_chatwoot_inbox_id(instance_name)
          return nil if ENV["CHATWOOT_URL"].blank? || ENV["CHATWOOT_API_TOKEN"].blank?
          inbox = ::Chatwoot::Client.from_env.find_inbox_by_name(instance_name)
          inbox ? (inbox[:id] || inbox["id"]) : nil
        rescue => e
          Rails.logger.warn "[WhatsApp] Não foi possível capturar inbox_id do Chatwoot: #{e.message}"
          nil
        end

        def evolution_status(client, instance_id)
          state = client.connection_state(instance_id)
          case state
          when "open"             then "connected"
          when "close", "refused" then "disconnected"
          when "connecting"       then "connecting"
          end
        rescue => e
          Rails.logger.warn "[WhatsApp] Erro ao consultar Evolution para #{instance_id}: #{e.message}"
          nil
        end

        def auto_configure_chatwoot
          return if ENV["CHATWOOT_URL"].blank? || ENV["CHATWOOT_API_TOKEN"].blank?

          config = current_workspace.chatwoot_config ||
                   current_workspace.build_chatwoot_config

          return if config.persisted? && config.chatwoot_url.present?

          config.assign_attributes(
            chatwoot_url:        ENV["CHATWOOT_URL"],
            chatwoot_account_id: ENV.fetch("CHATWOOT_ACCOUNT_ID", "1")
          )
          config.chatwoot_api_token = ENV["CHATWOOT_API_TOKEN"]
          config.save if config.valid?
        rescue => e
          Rails.logger.warn "[WhatsApp] auto_configure_chatwoot failed: #{e.message}"
        end
      end
    end
  end
end
