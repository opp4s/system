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

          config = current_workspace.chatwoot_config
          unless config
            return render json: { error: "Chatwoot não configurado neste workspace" },
                          status: :unprocessable_entity
          end

          conv = @card.conversations.order(created_at: :desc).first
          conv ||= auto_discover_conversation(config)

          unless conv
            return render json: {
              error: "Card não possui conversa Chatwoot vinculada. " \
                     "Aguarde o cliente entrar em contato ou vincule manualmente via POST /cards/:id/link_conversation"
            }, status: :unprocessable_entity
          end

          client  = ::Chatwoot::Client.new(config)
          private = message_params[:private_note].in?([true, "true"])

          cw_msg = if attachment
            client.send_message_with_attachment(
              conv.chatwoot_conversation_id,
              content:    content,
              attachment: attachment,
              private:    private
            )
          else
            client.send_message(conv.chatwoot_conversation_id, content, private: private)
          end

          # Persistir na tabela messages local — upsert para cobrir race com webhook
          attachment_meta = attachment ? [{
            filename:     attachment.original_filename,
            content_type: attachment.content_type,
            size:         attachment.size,
            url:          cw_msg.dig(:attachments, 0, :data_url) ||
                          cw_msg.dig(:attachments, 0, :file_url)
          }.compact] : []

          msg_record = Message.find_or_initialize_by(
            workspace:           current_workspace,
            chatwoot_message_id: cw_msg[:id].to_s
          )
          msg_record.assign_attributes(
            card:         @card,
            conversation: conv,
            content:      content.presence || attachment&.original_filename || "",
            message_type: "outgoing",
            channel:      "whatsapp",
            sender_name:  current_user.name,
            attachments:  attachment_meta
          )
          msg_record.save!

          event = CardEvent.create!(
            card:       @card,
            workspace:  current_workspace,
            user:       current_user,
            event_type: "message_sent",
            payload:    {
              content:         content,
              private_note:    private,
              conversation_id: conv.chatwoot_conversation_id,
              chatwoot_msg_id: cw_msg[:id],
              attachments:     attachment_meta
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
          params.require(:message).permit(:content, :private_note, :attachment)
        end

        def validate_attachment(file)
          return "Tipo de arquivo não permitido (#{file.content_type})" unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
          return "Arquivo excede o limite de 16MB (#{(file.size / 1.megabyte.to_f).round(1)}MB)" if file.size > MAX_SIZE_BYTES
          nil
        end

        def auto_discover_conversation(config)
          return nil if @card.contact_phone.blank?

          client  = ::Chatwoot::Client.new(config)
          results = client.find_contact_by_phone(@card.contact_phone)
          contacts_payload = results[:payload] || []
          return nil if contacts_payload.empty?

          cw_contact = contacts_payload.first
          convs      = client.contact_conversations(cw_contact[:id])
          cw_conv    = (convs[:payload] || []).find { |c| c[:status] == "open" } ||
                       (convs[:payload] || []).first
          return nil unless cw_conv

          conv = Conversation.find_or_initialize_by(
            workspace:                current_workspace,
            chatwoot_conversation_id: cw_conv[:id]
          )
          conv.assign_attributes(
            chatwoot_account_id: config.chatwoot_account_id,
            contact_id:          cw_contact[:id],
            status:              cw_conv[:status] || "open",
            last_activity_at:    Time.current,
            card:                @card
          )
          conv.save!
          conv
        rescue => e
          Rails.logger.warn "[MessagesController] auto_discover failed: #{e.message}"
          nil
        end

        def event_payload(event)
          {
            id:          event.id,
            event_type:  event.event_type,
            payload:     event.payload,
            user:        event.user && { id: event.user.id, name: event.user.name },
            created_at:  event.created_at
          }
        end
      end
    end
  end
end
