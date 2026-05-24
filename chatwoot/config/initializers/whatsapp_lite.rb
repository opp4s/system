require Rails.root.join('lib', 'whatsapp_lite', 'engine')

plugin_migrations = Rails.root.join('db', 'migrate_plugin')
Rails.application.config.paths['db/migrate'] << plugin_migrations.to_s if plugin_migrations.exist?

# Rotas: after_initialize pode chamar routes.prepend a qualquer momento após boot completo.
Rails.application.config.after_initialize do
  Rails.application.routes.prepend do
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :accounts, only: [] do
          post   'whatsapp_lite/connect',
                 controller: '/whatsapp_lite/api/connect',    action: :create
          get    'whatsapp_lite/status',
                 controller: '/whatsapp_lite/api/status',     action: :show
          post   'whatsapp_lite/refresh',
                 controller: '/whatsapp_lite/api/refresh',    action: :create
          get    'whatsapp_lite/instances',
                 controller: '/whatsapp_lite/api/instances',  action: :index
          delete 'whatsapp_lite/instances',
                 controller: '/whatsapp_lite/api/instances',  action: :destroy
          post   'whatsapp_lite/webhook/:instance_id',
                 controller: '/whatsapp_lite/api/webhook',    action: :create
        end
      end
    end
  end
end

# Listener: to_prepare garante que dispatcher já existe (criado em event_handlers.rb via to_prepare).
# event_handlers.rb (e < w) registra seu to_prepare antes do nosso — dispatcher disponível aqui.
Rails.application.config.to_prepare do
  next unless Rails.configuration.respond_to?(:dispatcher) &&
              Rails.configuration.dispatcher.respond_to?(:sync_dispatcher)

  Rails.configuration.dispatcher.sync_dispatcher.subscribe(
    WhatsappLite::Listeners::MessageListener.instance
  )
  Rails.logger.info "[whatsapp_lite] MessageListener subscribed to sync_dispatcher (pid=#{Process.pid})"
end
