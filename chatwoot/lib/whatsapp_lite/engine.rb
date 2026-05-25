module WhatsappLite
  class Engine < Rails::Engine
    isolate_namespace WhatsappLite
    # Rotas desenhadas em config/initializers/whatsapp_lite.rb via Rails.application.routes.draw
    # (load_config_initializers roda após add_routing_paths — routes.draw pode ser chamado a qualquer momento)

    config.after_initialize do
      require Rails.root.join('lib', 'whatsapp_lite', 'integration_app_concern')
      Integrations::App.prepend(WhatsappLite::IntegrationAppConcern) if defined?(Integrations::App)
    end
  end
end
