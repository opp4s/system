module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :require_workspace!

      def index
        authorize Conversation.new(workspace: current_workspace), :index?

        # Última mensagem por card (para last_message, last_message_at, last_message_type)
        last_msgs_sql = Message
          .where(workspace_id: current_workspace.id)
          .select("DISTINCT ON (card_id) card_id, content, message_type, created_at")
          .order("card_id, created_at DESC")
          .to_sql

        # Última mensagem incoming por card (somente incoming tem whatsapp_instance_id)
        last_incoming_sql = Message
          .where(workspace_id: current_workspace.id, message_type: "incoming")
          .select("DISTINCT ON (card_id) card_id, whatsapp_instance_id")
          .order("card_id, created_at DESC")
          .to_sql

        cards = current_workspace.cards
          .active
          .joins("JOIN (#{last_msgs_sql}) AS lm ON lm.card_id = cards.id")
          .joins("JOIN stages ON stages.id = cards.stage_id")
          .joins("LEFT JOIN (#{last_incoming_sql}) AS li ON li.card_id = cards.id")
          .joins("LEFT JOIN whatsapp_instances ON whatsapp_instances.id = li.whatsapp_instance_id")
          .joins("LEFT JOIN contacts ON contacts.phone_number = cards.contact_phone AND contacts.workspace_id = cards.workspace_id")
          .select(
            "cards.id AS card_id",
            "COALESCE(contacts.name, cards.contact_name) AS contact_name",
            "COALESCE(contacts.phone_number, cards.contact_phone) AS contact_phone",
            "lm.content AS last_message",
            "lm.created_at AS last_message_at",
            "lm.message_type AS last_message_type",
            "cards.title AS card_title",
            "stages.name AS card_stage",
            "stages.color AS card_stage_color",
            "whatsapp_instances.phone_number AS whatsapp_instance_phone"
          )
          .order("lm.created_at DESC")

        unread_counts = Message
          .where(workspace_id: current_workspace.id, message_type: "incoming", embedded_at: nil)
          .group(:card_id)
          .count

        render json: {
          data: cards.map { |c|
            {
              id:                      c.card_id,
              card_id:                 c.card_id,
              contact_name:            c.contact_name,
              contact_phone:           c.contact_phone,
              last_message:            c.last_message,
              last_message_at:         c.last_message_at,
              last_message_type:       c.last_message_type,
              unread_count:            unread_counts[c.card_id] || 0,
              card_title:              c.card_title,
              card_stage:              c.card_stage,
              card_stage_color:        c.card_stage_color,
              whatsapp_instance_phone: c.whatsapp_instance_phone
            }
          }
        }
      end
    end
  end
end
