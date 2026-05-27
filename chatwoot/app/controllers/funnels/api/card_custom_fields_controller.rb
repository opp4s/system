module Funnels
  module Api
    # GET  /api/v1/accounts/:id/funnels/:fid/cards/:card_id/custom_fields
    # PATCH /api/v1/accounts/:id/funnels/:fid/cards/:card_id/custom_fields
    class CardCustomFieldsController < BaseController
      before_action :set_funnel
      before_action :set_card

      def index
        fields = account_custom_attributes.map do |attr|
          value_record = @card.custom_field_values.find { |cfv| cfv.custom_attribute_id == attr.id }
          {
            attribute_id:           attr.id,
            attribute_key:          attr.attribute_key,
            attribute_display_name: attr.attribute_display_name,
            attribute_display_type: attr.attribute_display_type,
            attribute_values:       attr.attribute_values,
            value:                  value_record&.value
          }
        end
        render json: fields
      end

      # Payload: { fields: [{ attribute_id: 1, value: "foo" }, ...] }
      def update
        fields_param = params.require(:fields)

        ActiveRecord::Base.transaction do
          fields_param.each do |fp|
            attr = account_custom_attributes.find_by!(id: fp[:attribute_id])
            cfv  = @card.custom_field_values.find_or_initialize_by(custom_attribute: attr)
            cfv.value = fp[:value]
            cfv.save!
          end
        end

        @card.record_event('card_updated', user: current_user, payload: { updated_fields: fields_param.map { |f| f[:attribute_id] } })
        Funnels::Broadcaster.card_event(@card, 'card_updated')

        render json: { success: true }
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: "Atributo não encontrado: #{e.message}" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def set_funnel
        @funnel = @account.funnels.find(params[:funnel_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil não encontrado' }, status: :not_found
      end

      def set_card
        @card = @funnel.cards.includes(:custom_field_values).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Card não encontrado' }, status: :not_found
      end

      # Usa apenas custom attributes do tipo 'contact' ou sem modelo (genéricos)
      def account_custom_attributes
        @account_custom_attributes ||= CustomAttribute
                                         .where(account: @account)
                                         .order(:attribute_display_name)
      end
    end
  end
end
