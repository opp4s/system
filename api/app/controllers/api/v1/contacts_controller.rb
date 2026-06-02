module Api
  module V1
    class ContactsController < ApplicationController
      before_action :require_workspace!
      before_action :set_contact, only: [:show]

      PER_PAGE = 25

      def index
        authorize Contact.new(workspace: current_workspace), :index?

        contacts = current_workspace.contacts.ordered
        total    = contacts.count
        page     = [params[:page].to_i, 1].max
        items    = contacts.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

        render json: {
          data: items.map { |c| contact_payload(c) },
          meta: { total: total, page: page, per_page: PER_PAGE, pages: (total.to_f / PER_PAGE).ceil }
        }
      end

      def search
        authorize Contact.new(workspace: current_workspace), :search?

        q = params[:q].to_s.strip
        return render json: { error: "Parâmetro q é obrigatório" }, status: :bad_request if q.blank?

        contacts = current_workspace.contacts.search_by(q).ordered.limit(20)
        render json: { data: contacts.map { |c| contact_payload(c) } }
      end

      def show
        authorize @contact
        render json: { data: contact_payload(@contact, detailed: true) }
      end

      private

      def set_contact
        @contact = current_workspace.contacts.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Contato não encontrado" }, status: :not_found
      end

      def contact_payload(contact, detailed: false)
        payload = {
          id:           contact.id,
          name:         contact.name,
          email:        contact.email,
          phone_number: contact.phone_number,
          avatar_url:   contact.avatar_url,
          created_at:   contact.created_at
        }
        if detailed
          payload[:additional_attributes] = contact.additional_attributes
          payload[:custom_attributes]     = contact.custom_attributes
        end
        payload
      end
    end
  end
end
