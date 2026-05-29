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

        # POST /api/v1/chatwoot/quick_connect
        def quick_connect
          config = current_workspace.chatwoot_config ||
                   current_workspace.build_chatwoot_config

          authorize config, :configure?, policy_class: ChatwootConfigPolicy

          chatwoot_url   = ENV["CHATWOOT_URL"]
          api_token      = ENV["CHATWOOT_API_TOKEN"]
          account_id     = params[:account_id].to_s

          return render json: { error: "CHATWOOT_URL e CHATWOOT_API_TOKEN não configurados no servidor" },
                        status: :unprocessable_entity if chatwoot_url.blank? || api_token.blank?

          return render json: { error: "account_id é obrigatório" },
                        status: :bad_request if account_id.blank?

          config.assign_attributes(
            chatwoot_url:        chatwoot_url,
            chatwoot_account_id: account_id
          )
          config.chatwoot_api_token = api_token

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
              account_name:        info[:name]
            }
          }, status: config.previously_new_record? ? :created : :ok
        end

        private

        def configure_params
          params.require(:chatwoot).permit(
            :chatwoot_url, :account_id, :api_token, :inbox_id
          )
        end
      end
    end
  end
end
