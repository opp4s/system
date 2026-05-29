module Api
  module V1
    module Whatsapp
      class ConnectionsController < ApplicationController
        before_action :require_workspace!

        # POST /api/v1/whatsapp/connect
        # Body: { phone_number: "+5511999999999" }  — opcional
        def connect
          raw_phone = params[:phone_number].to_s.gsub(/\D/, "")
          phone         = raw_phone.length >= 10 ? raw_phone : nil
          instance_name = phone \
            ? "zavy-#{current_workspace.id}-#{phone}" \
            : "zavy-#{current_workspace.id}-#{SecureRandom.uuid}"

          client = ::Whatsapp::EvolutionClient.new
          state  = client.connection_state(instance_name)

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

          # Cria instância se não existir, depois busca QR separadamente
          # (Chatwoot suprime qrcode na resposta do create — get_qr sempre tem)
          client.create_instance(instance_name, workspace_id: current_workspace.id) if state == "not_found"

          result = if params[:method] == "pairing" && phone
            client.get_pairing_code(instance_name, phone)
          else
            client.get_qr(instance_name)
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
        end

        # GET /api/v1/whatsapp/status
        # Sincroniza status com Evolution antes de retornar
        def status
          instances = current_workspace.whatsapp_instances.order(:created_at)
          client    = ::Whatsapp::EvolutionClient.new

          result = instances.map do |wi|
            real_status = evolution_status(client, wi.instance_id)
            if real_status && real_status != wi.status
              wi.update_columns(status: real_status)
              wi.status = real_status
            end
            instance_payload(wi)
          end

          render json: { data: { instances: result } }
        end

        # POST /api/v1/whatsapp/disconnect
        # Body: { instance_id: "zavy-30-..." }
        # Faz logout na Evolution (desconecta WhatsApp mas mantém a instância)
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
        # Body: { instance_id: "zavy-30-..." }
        # Remove instância da Evolution E do banco
        def destroy
          instance_name = params.require(:instance_id)
          wi = current_workspace.whatsapp_instances.find_by(instance_id: instance_name)

          unless wi
            return render json: { data: { deleted: true, message: "Instância não encontrada" } }
          end

          ::Whatsapp::EvolutionClient.new.delete_instance(instance_name)
          wi.destroy!

          render json: { data: { deleted: true, instance_id: instance_name } }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        private

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

        def instance_payload(wi)
          {
            instance_id: wi.instance_id,
            phone:       wi.phone_number.presence,
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
