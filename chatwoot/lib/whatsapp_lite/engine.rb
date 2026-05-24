module WhatsappLite
  class Engine < Rails::Engine
    isolate_namespace WhatsappLite
    # Rotas desenhadas em config/initializers/whatsapp_lite.rb via Rails.application.routes.draw
    # (load_config_initializers roda após add_routing_paths — routes.draw pode ser chamado a qualquer momento)
  end
end
