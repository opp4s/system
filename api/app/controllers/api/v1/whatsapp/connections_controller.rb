module Api
  module V1
    module Whatsapp
      class ConnectionsController < ApplicationController
        before_action :require_workspace!

        # POST /api/v1/whatsapp/connect
        # Body: { phone_number: "+5511999999999" }
        def connect
          phone = params.require(:phone_number).to_s.gsub(/\D/, "")
          return render json: { error: "phone_number inválido" }, status: :bad_request if phone.length < 10

          instance_name = "zavy-#{current_workspace.id}-#{phone}"
          client = ::Whatsapp::EvolutionClient.new

          state = client.connection_state(instance_name)

          if state == "open"
            wi = current_workspace.whatsapp_instances.find_or_initialize_by(instance_id: instance_name)
            wi.update!(phone_number: phone, status: "connected")
            return render json: {
              data: {
                instance_id: instance_name,
                connected:   true,
                phone:       phone,
                message:     "WhatsApp já está conectado"
              }
            }
          end

          # Cria ou reconecta instância
          if params[:method] == "pairing"
            client.create_instance(instance_name, workspace_id: current_workspace.id) if state == "not_found"
            result = client.get_pairing_code(instance_name, phone)
          else
            result = if state == "not_found"
              client.create_instance(instance_name, workspace_id: current_workspace.id)
            else
              client.get_qr(instance_name)
            end
          end

          wi = current_workspace.whatsapp_instances.find_or_initialize_by(instance_id: instance_name)
          wi.update!(phone_number: phone, status: "qr_pending")

          auto_configure_chatwoot

          render json: {
            data: {
              instance_id:    result[:instance_id] || instance_name,
              qr_code_base64: result[:qr_base64],
              pairing_code:   result[:pairing_code],
              expires_at:     result[:expires_at]
            }
          }
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro na Evolution API: #{e.message}" }, status: :unprocessable_entity
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        # GET /api/v1/whatsapp/status
        def status
          instances = current_workspace.whatsapp_instances.order(:created_at)
          render json: {
            data: {
              instances: instances.map { |wi| instance_payload(wi) }
            }
          }
        end

        # POST /api/v1/whatsapp/disconnect
        # Body: { instance_id: "zavy-30-5511999999999" }
        def disconnect
          instance_name = params.require(:instance_id)
          wi = current_workspace.whatsapp_instances.find_by(instance_id: instance_name)

          unless wi
            return render json: { data: { disconnected: true, message: "Instância não encontrada" } }
          end

          client = ::Whatsapp::EvolutionClient.new
          client.delete_instance(instance_name)
          wi.destroy

          render json: { data: { disconnected: true } }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro ao desconectar: #{e.message}" }, status: :unprocessable_entity
        end

        private

        def instance_payload(wi)
          {
            instance_id: wi.instance_id,
            phone:       wi.phone_number,
            status:      wi.status,
            created_at:  wi.created_at
          }
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
