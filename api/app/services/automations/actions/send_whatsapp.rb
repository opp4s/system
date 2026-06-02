module Automations
  module Actions
    class SendWhatsapp
      def self.run(card, config)
        template = config["message"].to_s
        return { success: false, error: "message template vazio", type: "send_whatsapp" } if template.blank?

        content = interpolate(template, card)

        wi = WhatsappInstance.find_by(workspace: card.workspace, pipeline_id: card.pipeline_id, status: "connected")
        unless wi
          wi = WhatsappInstance.find_by(workspace: card.workspace, status: "connected")
        end
        return { success: false, error: "Sem instância WhatsApp conectada", type: "send_whatsapp" } unless wi

        return { success: false, error: "Card sem telefone de contato", type: "send_whatsapp" } if card.contact_phone.blank?

        user = card.workspace.workspace_memberships.first&.user
        msg = Evolution::MessageSender.new(wi, card, user || OpenStruct.new(name: "Sistema"),
                                           content: content).call

        card.card_events.create!(
          workspace_id: card.workspace_id,
          event_type:   "automation_message_sent",
          payload:      { content: content, automation: true, source_id: msg.source_id }
        )

        { success: true, type: "send_whatsapp", source_id: msg.source_id }
      rescue => e
        { success: false, type: "send_whatsapp", error: e.message }
      end

      def self.interpolate(template, card)
        template
          .gsub("{contact_name}",  card.contact_name.to_s)
          .gsub("{contact_phone}", card.contact_phone.to_s)
          .gsub("{contact_email}", card.contact_email.to_s)
          .gsub("{title}",         card.title.to_s)
          .gsub("{value}",         card.value.to_s)
          .gsub("{stage_name}",    card.stage&.name.to_s)
          .gsub("{days_in_stage}", card.days_in_stage.to_s)
      end
      private_class_method :interpolate
    end
  end
end
