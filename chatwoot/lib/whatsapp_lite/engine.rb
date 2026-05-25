module WhatsappLite
  class Engine < Rails::Engine
    isolate_namespace WhatsappLite
    # Rotas desenhadas em config/initializers/whatsapp_lite.rb via Rails.application.routes.draw
    # (load_config_initializers roda após add_routing_paths — routes.draw pode ser chamado a qualquer momento)

    config.after_initialize do
      require Rails.root.join('lib', 'whatsapp_lite', 'account_helpers')
      require Rails.root.join('lib', 'whatsapp_lite', 'integration_app_concern')
      Integrations::App.prepend(WhatsappLite::IntegrationAppConcern) if defined?(Integrations::App)

      primary_id = WhatsappLite::AccountHelpers.primary_account_id
      if Account.exists?(id: primary_id)
        Rails.logger.info "[whatsapp_lite] Primary account ID: #{primary_id}"
      else
        Rails.logger.warn "[whatsapp_lite] Primary account ID #{primary_id} não existe ainda — credenciais não disponíveis"
      end
    end
  end
end
