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

          # Verifica se já existe instância conectada
          state = client.connection_state(instance_name)
          if state == "open"
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
          result = if state == "not_found"
            client.create_instance(instance_name, workspace_id: current_workspace.id)
          else
            client.get_qr(instance_name)
          end

          # Auto-configura ChatwootConfig com credenciais do servidor
          auto_configure_chatwoot

          # Persiste instance_id nas settings
          save_whatsapp_settings(instance_name, phone)

          render json: {
            data: {
              instance_id:  result[:instance_id] || instance_name,
              qr_code_base64: result[:qr_base64],
              expires_at:   result[:expires_at]
            }
          }
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro na Evolution API: #{e.message}" }, status: :unprocessable_entity
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        # GET /api/v1/whatsapp/status
        def status
          config = current_workspace.chatwoot_config
          instance_name = config&.settings&.dig("whatsapp_instance_id")

          unless instance_name
            return render json: { data: { connected: false, instance_id: nil, phone: nil } }
          end

          client = ::Whatsapp::EvolutionClient.new
          state  = client.connection_state(instance_name)

          render json: {
            data: {
              connected:   state == "open",
              state:       state,
              instance_id: instance_name,
              phone:       config.settings["whatsapp_phone"]
            }
          }
        end

        # POST /api/v1/whatsapp/disconnect
        def disconnect
          config = current_workspace.chatwoot_config
          instance_name = config&.settings&.dig("whatsapp_instance_id")

          unless instance_name
            return render json: { data: { disconnected: true, message: "Nenhuma instância encontrada" } }
          end

          client = ::Whatsapp::EvolutionClient.new
          client.delete_instance(instance_name)

          # Remove instance_id das settings
          if config
            new_settings = (config.settings || {}).except("whatsapp_instance_id", "whatsapp_phone")
            config.update_columns(settings: new_settings)
          end

          render json: { data: { disconnected: true } }
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro ao desconectar: #{e.message}" }, status: :unprocessable_entity
        end

        private

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

        def save_whatsapp_settings(instance_name, phone)
          config = current_workspace.chatwoot_config
          return unless config&.persisted?

          new_settings = (config.settings || {}).merge(
            "whatsapp_instance_id" => instance_name,
            "whatsapp_phone"       => phone
          )
          config.update_columns(settings: new_settings)
        rescue => e
          Rails.logger.warn "[WhatsApp] save_whatsapp_settings failed: #{e.message}"
        end
      end
    end
  end
end
