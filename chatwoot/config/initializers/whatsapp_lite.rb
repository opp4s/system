require Rails.root.join('lib', 'whatsapp_lite', 'engine')

plugin_migrations = Rails.root.join('db', 'migrate_plugin')
Rails.application.config.paths['db/migrate'] << plugin_migrations.to_s if plugin_migrations.exist?

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
