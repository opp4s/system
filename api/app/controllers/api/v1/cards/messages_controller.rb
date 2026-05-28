module Api
  module V1
    module Cards
      class MessagesController < ApplicationController
        before_action :require_workspace!
        before_action :set_card

        # POST /api/v1/cards/:card_id/messages
        def create
          authorize @card, :send_message?

          if message_params[:content].blank?
            return render json: { error: "Conteúdo da mensagem é obrigatório" },
                          status: :unprocessable_entity
          end

          conv = @card.conversations.order(created_at: :desc).first
          unless conv
            return render json: { error: "Card não possui conversa Chatwoot vinculada" },
                          status: :unprocessable_entity
          end

          config = current_workspace.chatwoot_config
          unless config
            return render json: { error: "Chatwoot não configurado neste workspace" },
                          status: :unprocessable_entity
          end

          client  = ::Chatwoot::Client.new(config)
          cw_msg  = client.send_message(
            conv.chatwoot_conversation_id,
            message_params[:content],
            private: message_params[:private_note] == true || message_params[:private_note] == "true"
          )

          event = CardEvent.create!(
            card:       @card,
            workspace:  current_workspace,
            user:       current_user,
            event_type: "message_sent",
            payload:    {
              content:         message_params[:content],
              private_note:    message_params[:private_note].in?([true, "true"]),
              conversation_id: conv.chatwoot_conversation_id,
              chatwoot_msg_id: cw_msg[:id]
            }
          )

          ActionCable.server.broadcast(
            "pipeline_#{@card.pipeline_id}",
            { event: "message_sent", card_id: @card.id, event_data: event_payload(event) }
          )

          render json: { data: event_payload(event) }, status: :created

        rescue ::Chatwoot::Client::ApiError => e
          render json: { error: "Erro ao enviar mensagem: #{e.message}" },
                 status: :unprocessable_entity
        end

        private

        def set_card
          @card = current_workspace.cards.find(params[:card_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Card não encontrado" }, status: :not_found
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
