require Rails.root.join('lib', 'funnels', 'engine')
require Rails.root.join('lib', 'funnels', 'broadcaster')
require Rails.root.join('lib', 'funnels', 'seeder')
require Rails.root.join("lib", "funnels", "account_concern")

# Adiciona migrations do plugin
plugin_migrations = Rails.root.join('db', 'migrate_funnels')
Rails.application.config.paths['db/migrate'] << plugin_migrations.to_s if plugin_migrations.exist?

Rails.application.config.after_initialize do
  # Associação Account -> Funnels
  Account.include(Funnels::AccountConcern) unless Account.reflect_on_association(:funnels) rescue nil
  Rails.application.routes.prepend do
    namespace :api, defaults: { format: :json } do
      namespace :v1 do
        resources :accounts, only: [] do
          post "funnels/reorder", controller: "/funnels/api/funnels", action: :reorder
          get "funnels/cards_by_conversation", controller: "/funnels/api/cards", action: :by_conversation
          resources :funnels,
                    controller: '/funnels/api/funnels',
                    only: %i[index show create update destroy] do
            member { get :analytics }

            resources :stages,
                      controller: '/funnels/api/stages',
                      only: %i[index create update destroy] do
              collection { post :reorder }
              resources :automations,
                        controller: '/funnels/api/stage_automations',
                        only: %i[index create update destroy]
            end

            resources :cards,
                      controller: '/funnels/api/cards',
                      only: %i[index show create update destroy] do
              member do
                post  :move
                post  :transfer
                post  :archive
                get   :timeline
                post  :link_conversation
                delete :link_conversation, action: :unlink_conversation
                get   :custom_fields,  controller: '/funnels/api/card_custom_fields', action: :index
                patch :custom_fields,  controller: '/funnels/api/card_custom_fields', action: :update
              end
            end
          end
        end
      end
    end
  end
end
