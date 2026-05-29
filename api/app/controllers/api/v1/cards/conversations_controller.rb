module Api
  module V1
    module Cards
      class ConversationsController < ApplicationController
        before_action :require_workspace!
        before_action :set_card

        # POST /api/v1/cards/:id/link_conversation
        def link
          authorize @card, :update?

          cw_conv_id = params[:chatwoot_conversation_id].to_i
          if cw_conv_id == 0
            return render json: { error: "chatwoot_conversation_id é obrigatório" },
                          status: :bad_request
          end

          account_id = current_workspace.chatwoot_config&.chatwoot_account_id || ""

          conv = Conversation.find_or_initialize_by(
            workspace:               current_workspace,
            chatwoot_conversation_id: cw_conv_id
          )

          if conv.new_record?
            conv.assign_attributes(
              chatwoot_account_id: account_id,
              status:              "open",
              last_activity_at:    Time.current
            )
          end

          conv.card = @card

          unless conv.save
            return render_unprocessable(conv)
          end

          CardEvent.create!(
            card:       @card,
            workspace:  current_workspace,
            user:       current_user,
            event_type: "conversation_linked",
            payload:    { chatwoot_conversation_id: cw_conv_id }
          )

          ActionCable.server.broadcast(
            "pipeline_#{@card.pipeline_id}",
            { event: "conversation_linked", card_id: @card.id,
              chatwoot_conversation_id: cw_conv_id }
          )

          render json: {
            data: {
              card_id:                  @card.id,
              conversation_id:          conv.id,
              chatwoot_conversation_id: cw_conv_id
            }
          }
        end

        # DELETE /api/v1/cards/:id/unlink_conversation
        def unlink
          authorize @card, :update?

          conv = @card.conversations.order(created_at: :desc).first
          unless conv
            return render json: { error: "Card não possui conversa vinculada" },
                          status: :not_found
          end

          cw_conv_id = conv.chatwoot_conversation_id
          conv.update!(card: nil)

          CardEvent.create!(
            card:       @card,
            workspace:  current_workspace,
            user:       current_user,
            event_type: "conversation_unlinked",
            payload:    { chatwoot_conversation_id: cw_conv_id }
          )

          ActionCable.server.broadcast(
            "pipeline_#{@card.pipeline_id}",
            { event: "conversation_unlinked", card_id: @card.id }
          )

          render json: { data: { message: "Conversa desvinculada do card" } }
        end

        private

        def set_card
          @card = current_workspace.cards.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Card não encontrado" }, status: :not_found
        end
      end
    end
  end
end
