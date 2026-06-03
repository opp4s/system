module Api
  module V1
    module Cards
      class MessagesController < ApplicationController
        before_action :require_workspace!
        before_action :set_card

        ALLOWED_CONTENT_TYPES = %w[
          image/png image/jpeg image/jpg image/webp image/gif
          application/pdf
          audio/ogg audio/mpeg audio/mp4 audio/aac
          video/mp4 video/quicktime
          application/msword
          application/vnd.openxmlformats-officedocument.wordprocessingml.document
        ].freeze
        MAX_SIZE_BYTES = 16.megabytes

        # POST /api/v1/cards/:card_id/messages
        def create
          authorize @card, :send_message?

          attachment = message_params[:attachment]
          content    = message_params[:content].to_s.strip

          if content.blank? && attachment.nil?
            return render json: { error: "Conteúdo ou arquivo é obrigatório" },
                          status: :unprocessable_entity
          end

          if attachment
            err = validate_attachment(attachment)
            return render json: { error: err }, status: :unprocessable_entity if err
          end

          wi = whatsapp_instance_for_card
          unless wi
            return render json: { error: "Nenhuma instância WhatsApp conectada neste pipeline" },
                          status: :unprocessable_entity
          end

          unless @card.contact_phone.present?
            return render json: { error: "Card sem telefone de contato" },
                          status: :unprocessable_entity
          end

          in_reply_to = message_params[:in_reply_to].presence

          msg = Evolution::MessageSender.new(
            wi, @card, current_user,
            content:     content,
            attachment:  attachment,
            in_reply_to: in_reply_to
          ).call

          event = CardEvent.create!(
            card:       @card,
            workspace:  current_workspace,
            user:       current_user,
            event_type: "message_sent",
            payload:    {
              content:      msg.content,
              source_id:    msg.source_id,
              attachments:  msg.attachments,
              private_note: false
            }.compact
          )

          ActionCable.server.broadcast(
            "pipeline_#{@card.pipeline_id}",
            { event: "message_sent", card_id: @card.id, event_data: event_payload(event) }
          )

          render json: { data: event_payload(event) }, status: :created

        rescue Evolution::MessageSender::SendError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        # Prioridade: a instância que ORIGINOU a conversa (última mensagem incoming
        # com instância registrada). Garante que a resposta sai pelo mesmo número que
        # o lead contatou — crítico quando o pipeline tem múltiplas instâncias.
        def whatsapp_instance_for_card
          origin = @card.messages
                        .where(message_type: "incoming")
                        .where.not(whatsapp_instance_id: nil)
                        .order(created_at: :desc)
                        .first
          if origin&.whatsapp_instance&.status == "connected"
            return origin.whatsapp_instance
          end

          # Fallback: instância conectada do pipeline (comportamento legado)
          return nil unless @card.pipeline_id.present?
          WhatsappInstance.find_by(
            workspace:   current_workspace,
            pipeline_id: @card.pipeline_id,
            status:      "connected"
          )
        end

        def set_card
          @card = current_workspace.cards.find(params[:card_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Card não encontrado" }, status: :not_found
        end

        def message_params
          params.require(:message).permit(:content, :private_note, :attachment, :in_reply_to)
        end

        def validate_attachment(file)
          return "Tipo de arquivo não permitido (#{file.content_type})" unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
          return "Arquivo excede o limite de 16MB (#{(file.size / 1.megabyte.to_f).round(1)}MB)" if file.size > MAX_SIZE_BYTES
          nil
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
