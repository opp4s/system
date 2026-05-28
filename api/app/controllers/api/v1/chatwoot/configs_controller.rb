module Api
  module V1
    module Chatwoot
      class ConfigsController < ApplicationController
        before_action :require_workspace!

        # GET /api/v1/chatwoot/status
        def status
          config = current_workspace.chatwoot_config
          unless config
            return render json: { data: { configured: false } }
          end

          authorize config, :show?, policy_class: ChatwootConfigPolicy

          begin
            client = ::Chatwoot::Client.new(config)
            info   = client.account_info
            render json: {
              data: {
                configured:         true,
                chatwoot_url:       config.chatwoot_url,
                chatwoot_account_id: config.chatwoot_account_id,
                chatwoot_inbox_id:  config.chatwoot_inbox_id,
                settings:           config.settings,
                account_name:       info[:name],
                connected:          true
              }
            }
          rescue ::Chatwoot::Client::ApiError => e
            render json: {
              data: {
                configured: true,
                connected:  false,
                error:      e.message
              }
            }
          end
        end

        # POST /api/v1/chatwoot/configure
        def configure
          config = current_workspace.chatwoot_config ||
                   current_workspace.build_chatwoot_config

          authorize config, :configure?, policy_class: ChatwootConfigPolicy

          config.assign_attributes(
            chatwoot_url:        configure_params[:chatwoot_url],
            chatwoot_account_id: configure_params[:account_id].to_s,
            chatwoot_inbox_id:   configure_params[:inbox_id]
          )
          config.chatwoot_api_token = configure_params[:api_token] if configure_params[:api_token].present?

          unless config.valid?
            return render_unprocessable(config)
          end

          # Validar conexão antes de salvar
          begin
            client = ::Chatwoot::Client.new(config)
            info   = client.account_info
          rescue ::Chatwoot::Client::ApiError => e
            return render json: {
              error:   "Não foi possível conectar ao Chatwoot: #{e.message}",
              details: { status: e.status }
            }, status: :unprocessable_entity
          end

          config.save!

          render json: {
            data: {
              configured:          true,
              connected:           true,
              chatwoot_url:        config.chatwoot_url,
              chatwoot_account_id: config.chatwoot_account_id,
              chatwoot_inbox_id:   config.chatwoot_inbox_id,
              account_name:        info[:name]
            }
          }, status: config.previously_new_record? ? :created : :ok
        end

        # PATCH /api/v1/chatwoot/settings
        def update_settings
          config = current_workspace.chatwoot_config
          return render json: { error: "Chatwoot não configurado" }, status: :unprocessable_entity unless config

          authorize config, :configure?, policy_class: ChatwootConfigPolicy

          allowed = %w[auto_create_card auto_create_pipeline_id auto_create_stage_id]
          new_settings = settings_params.to_h.slice(*allowed)
          config.settings = (config.settings || {}).merge(new_settings)
          config.save!

          render json: { data: config.settings }
        end

        private

        def configure_params
          params.require(:chatwoot).permit(
            :chatwoot_url, :account_id, :api_token, :inbox_id
          )
        end

        def settings_params
          params.require(:settings).permit(
            :auto_create_card, :auto_create_pipeline_id, :auto_create_stage_id
          )
        end
      end
    end
  end
end
