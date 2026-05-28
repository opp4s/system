module Automations
  module Actions
    class SendWhatsapp
      def self.run(card, config)
        template = config["message"]
        content = interpolate(template, card)
        
        conversation = card.conversations.order(created_at: :desc).first
        return { success: false, error: "Sem conversa vinculada", type: "send_whatsapp" } unless conversation

        chatwoot_id = conversation.chatwoot_conversation_id
        workspace = card.workspace
        
        begin
          client = Chatwoot::Client.new(workspace)
          result = client.send_message(chatwoot_id, content)
          
          card.card_events.create!(
            workspace_id: workspace.id,
            event_type: "automation_message_sent",
            payload: { 
              content: content, 
              automation: true,
              chatwoot_message_id: result[:id]
            }
          )
          
          { success: true, type: "send_whatsapp", chatwoot_msg_id: result[:id] }
        rescue => e
          { success: false, type: "send_whatsapp", error: e.message }
        end
      end

      private

      def self.interpolate(template, card)
        template
          .gsub({contact_name}, card.contact_name.to_s)
          .gsub({contact_phone}, card.contact_phone.to_s)
          .gsub({contact_email}, card.contact_email.to_s)
          .gsub({title}, card.title.to_s)
          .gsub({value}, card.value.to_s)
          .gsub({stage_name}, card.stage.name.to_s)
          .gsub({days_in_stage}, card.days_in_stage.to_s)
      end
    end
  end
end
