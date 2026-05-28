module Api
  module V1
    class ContactsController < ApplicationController
      before_action :require_workspace!
      before_action :set_contact, only: [:show]

      PER_PAGE = 25

      # GET /api/v1/contacts
      def index
        authorize Contact.new(workspace: current_workspace), :index?

        contacts = current_workspace.contacts.ordered
        total    = contacts.count
        page     = [params[:page].to_i, 1].max
        items    = contacts.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

        render json: {
          data: items.map { |c| contact_payload(c) },
          meta: {
            total:        total,
            page:         page,
            per_page:     PER_PAGE,
            pages:        (total.to_f / PER_PAGE).ceil
          }
        }
      end

      # GET /api/v1/contacts/search?q=...
      def search
        authorize Contact.new(workspace: current_workspace), :search?

        q = params[:q].to_s.strip
        if q.blank?
          return render json: { error: "Parâmetro q é obrigatório" }, status: :bad_request
        end

        contacts = current_workspace.contacts.search_by(q).ordered.limit(20)
        render json: { data: contacts.map { |c| contact_payload(c) } }
      end

      # GET /api/v1/contacts/:id
      def show
        authorize @contact

        convs = @contact.conversations.includes(:card).order(created_at: :desc)

        render json: {
          data: contact_payload(@contact, detailed: true, conversations: convs)
        }
      end

      # POST /api/v1/contacts/sync
      def sync
        authorize Contact.new(workspace: current_workspace), :sync?

        unless current_workspace.chatwoot_config
          return render json: { error: "Chatwoot não configurado neste workspace" },
                        status: :unprocessable_entity
        end

        ::Chatwoot::SyncContactsJob.perform_later(current_workspace.id)
        render json: { data: { message: "Sincronização iniciada em background" } }
      end

      private

      def set_contact
        @contact = current_workspace.contacts.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contato não encontrado" }, status: :not_found
      end

      def contact_payload(contact, detailed: false, conversations: nil)
        payload = {
          id:                    contact.id,
          chatwoot_contact_id:   contact.chatwoot_contact_id,
          name:                  contact.name,
          email:                 contact.email,
          phone_number:          contact.phone_number,
          avatar_url:            contact.avatar_url,
          last_synced_at:        contact.last_synced_at,
          created_at:            contact.created_at
        }

        if detailed
          payload[:additional_attributes] = contact.additional_attributes
          payload[:custom_attributes]     = contact.custom_attributes
          payload[:conversations]         = conversations&.map { |conv| conversation_payload(conv) } || []
        end

        payload
      end

      def conversation_payload(conv)
        {
          id:                       conv.id,
          chatwoot_conversation_id: conv.chatwoot_conversation_id,
          status:                   conv.status,
          last_activity_at:         conv.last_activity_at,
          card:                     conv.card && {
            id:         conv.card.id,
            title:      conv.card.title,
            pipeline_id: conv.card.pipeline_id,
            stage_id:   conv.card.stage_id
          }
        }
      end
    end
  end
end
