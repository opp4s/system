require Rails.root.join('lib', 'whatsapp_lite', 'engine')
require Rails.root.join('lib', 'whatsapp_lite', 'account_helpers')

# Merge plugin integration into APPS_CONFIG (loaded by 00_init.rb before this runs).
# Runs at top-level so it's available synchronously before any request.
plugin_yml = Rails.root.join('config', 'integration', 'whatsapp_lite.yml')
if plugin_yml.exist? && defined?(APPS_CONFIG)
  APPS_CONFIG.merge!(YAML.safe_load_file(plugin_yml))
end

# aws-sdk-s3 >= 1.210 defaults to request_checksum_calculation: "when_supported",
# which adds a CRC32 checksum that conflicts with ActiveStorage's content_md5.
# Set to "when_required" so only checksums explicitly requested are sent.
Aws.config.update(
  request_checksum_calculation: 'when_required',
  response_checksum_validation: 'when_required'
) if defined?(Aws)

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
          get    'whatsapp_lite/settings',
                 controller: '/whatsapp_lite/api/settings',   action: :show
          post   'whatsapp_lite/settings',
                 controller: '/whatsapp_lite/api/settings',   action: :update
          post   'whatsapp_lite/disconnect',
                 controller: '/whatsapp_lite/api/disconnect', action: :create
          post   'whatsapp_lite/reconnect',
                 controller: '/whatsapp_lite/api/reconnect',  action: :create
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

# Rate limiting para o webhook endpoint (proteção contra flood).
# Usa Rack::Attack que já está configurado no Chatwoot com Redis.
# Limite: 120 requests por minuto por instance_id (2/s burst tolerado).
if defined?(Rack::Attack)
  Rack::Attack.throttle('whatsapp_lite/webhook', limit: 120, period: 60) do |req|
    if req.path.match?(%r{/whatsapp_lite/webhook/}) && req.post?
      # Throttle por instance_id (extraído do path)
      req.path.split('/whatsapp_lite/webhook/').last&.split('.')&.first
    end
  end
end
