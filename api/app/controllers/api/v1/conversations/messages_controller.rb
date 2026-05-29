module Api
  module V1
    module Conversations
      class MessagesController < ApplicationController
        before_action :require_workspace!
        before_action :set_conversation

        # POST /api/v1/conversations/:conversation_id/messages
        def create
          authorize @conv, :send_message?

          if message_params[:content].blank?
            return render json: { error: "Conteúdo da mensagem é obrigatório" },
                          status: :unprocessable_entity
          end

          config = current_workspace.chatwoot_config
          unless config
            return render json: { error: "Chatwoot não configurado neste workspace" },
                          status: :unprocessable_entity
          end

          is_private = message_params[:private_note].in?([true, "true"])
          client     = ::Chatwoot::Client.new(config)
          cw_msg     = client.send_message(
            @conv.chatwoot_conversation_id,
            message_params[:content],
            private: is_private
          )

          card_event = nil
          if @conv.linked?
            card_event = CardEvent.create!(
              card:       @conv.card,
              workspace:  current_workspace,
              user:       current_user,
              event_type: "message_sent",
              payload:    {
                content:         message_params[:content],
                private_note:    is_private,
                conversation_id: @conv.chatwoot_conversation_id,
                chatwoot_msg_id: cw_msg[:id]
              }
            )

            ActionCable.server.broadcast(
              "pipeline_#{@conv.card.pipeline_id}",
              { event: "message_sent", card_id: @conv.card_id, event_data: event_payload(card_event) }
            )
          end

          render json: {
            data: {
              conversation_id:          @conv.id,
              chatwoot_conversation_id: @conv.chatwoot_conversation_id,
              chatwoot_message_id:      cw_msg[:id],
              content:                  message_params[:content],
              private_note:             is_private,
              card_event:               card_event && event_payload(card_event)
            }
          }, status: :created

        rescue ::Chatwoot::Client::ApiError => e
          render json: { error: "Erro ao enviar mensagem: #{e.message}" },
                 status: :unprocessable_entity
        end

        private

        def set_conversation
          @conv = current_workspace.conversations.find(params[:conversation_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Conversa não encontrada" }, status: :not_found
        end

        def message_params
          params.require(:message).permit(:content, :private_note)
        end

        def event_payload(event)
          {
            id:         event.id,
            event_type: event.event_type,
            payload:    event.payload,
            user:       event.user && { id: event.user.id, name: event.user.name },
            created_at: event.created_at
          }
        end
      end
    end
  end
end
