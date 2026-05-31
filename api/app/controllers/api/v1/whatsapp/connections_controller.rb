module Api
  module V1
    module Whatsapp
      class ConnectionsController < ApplicationController
        before_action :require_workspace!

        # POST /api/v1/whatsapp/connect
        def connect
          evo_client = ::Whatsapp::EvolutionClient.new

          # Reutilizar instância pendente (qr_pending/connecting) se existir
          # Evita criar nova instância a cada clique em "Conectar"
          pending = current_workspace.whatsapp_instances
                      .where(status: %w[qr_pending connecting])
                      .order(created_at: :desc)
                      .first

          if pending
            evo_state = evo_client.connection_state(pending.instance_id)

            if evo_state == "open"
              # Raro: conectou mas webhook não atualizou — corrigir status e retornar
              pending.update_columns(status: "connected")
              return render json: { data: instance_payload(pending.reload) }
            elsif abandoned?(pending)
              # Pendente velha (>5min sem conectar) — limpar e criar do zero
              cleanup_instance(pending, evo_client)
            elsif evo_state != "not_found"
              # Pendente recente — gerar QR novo para ela
              result = evo_client.get_qr(pending.instance_id)
              pending.update_columns(status: "qr_pending")
              return render json: {
                data: instance_payload(pending).merge(
                  qr_code_base64: result[:qr_base64],
                  expires_at:     result[:expires_at],
                  reused:         true
                )
              }
            else
              # Instância sumiu da Evolution — limpar e criar do zero
              cleanup_instance(pending, evo_client)
            end
          end

          # Criar nova instância com nome identificável (pending-hex ao invés de UUID longo)
          instance_name = "zavy-#{current_workspace.id}-pending-#{SecureRandom.hex(3)}"

          begin
            evo_client.create_instance(instance_name, workspace_id: current_workspace.id)

            result = evo_client.get_qr(instance_name)

            inbox_id = fetch_chatwoot_inbox_id(instance_name)

            wi = current_workspace.whatsapp_instances.create!(
              instance_id:       instance_name,
              status:            "qr_pending",
              chatwoot_inbox_id: inbox_id
            )

            auto_configure_chatwoot

            render json: {
              data: instance_payload(wi).merge(
                qr_code_base64: result[:qr_base64],
                expires_at:     result[:expires_at]
              )
            }
          rescue => e
            # Rollback: limpar Evolution + Chatwoot se falhou antes de salvar
            evo_client.delete_instance(instance_name) rescue nil
            if inbox_id
              begin; ::Chatwoot::Client.from_env.delete_inbox(inbox_id); rescue nil; end
            end
            raise e
          end
        rescue ::Whatsapp::EvolutionClient::ApiError => e
          render json: { error: "Erro na Evolution API: #{e.message}" }, status: :unprocessable_entity
        end

        # GET /api/v1/whatsapp/status
        # Uma chamada fetchInstances para todas as instâncias (captura status + phone)
        def status
          instances  = current_workspace.whatsapp_instances.includes(:pipeline).order(:created_at)
          evo_client = ::Whatsapp::EvolutionClient.new

          evo_data = evo_client.bulk_status(instances.map(&:instance_id))

          result = []
          instances.each do |wi|
            # Auto-cleanup: pendentes abandonadas (sem phone, >5min, não conectadas)
            if abandoned?(wi)
              cleanup_instance(wi, evo_client)
              next
            end

            evo = evo_data[wi.instance_id]
            if evo
              updates = {}
              updates[:status]       = evo[:status] if evo[:status] && evo[:status] != wi.status
              updates[:phone_number] = evo[:phone]  if evo[:phone].present? && wi.phone_number.blank?
              if updates.any?
                wi.update_columns(updates)
                wi.status       = updates[:status]       if updates[:status]
                wi.phone_number = updates[:phone_number] if updates[:phone_number]
              end
            end

            result << instance_payload(wi)
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

          cleanup_instance(wi, ::Whatsapp::EvolutionClient.new)

          render json: { data: { deleted: true, instance_id: instance_name } }
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        end

        private

        PENDING_TTL = 5.minutes

        # Pendente abandonada: sem phone, status não-connected, criada há >5min
        def abandoned?(wi)
          wi.phone_number.blank? &&
            %w[qr_pending connecting].include?(wi.status) &&
            wi.created_at < PENDING_TTL.ago
        end

        # Remove instância da Evolution, inbox do Chatwoot e registro do banco
        def cleanup_instance(wi, evo_client = ::Whatsapp::EvolutionClient.new)
          evo_client.delete_instance(wi.instance_id)

          begin
            cw = ::Chatwoot::Client.from_env
            inbox_id = wi.chatwoot_inbox_id ||
                       cw.find_inbox_by_name(wi.instance_id)&.then { |i| i[:id] || i["id"] }
            cw.delete_inbox(inbox_id) if inbox_id
          rescue => e
            Rails.logger.warn "[WhatsApp] Falha ao deletar inbox Chatwoot para #{wi.instance_id}: #{e.message}"
          end

          wi.destroy!
        end

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
