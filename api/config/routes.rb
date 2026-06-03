Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => "/cable"

  devise_for :users, skip: :all

  namespace :auth do
    post "register",        to: "registrations#create"
    post "login",           to: "sessions#create"
    delete "logout",        to: "sessions#destroy"
    post "forgot_password", to: "passwords#forgot"
    post "reset_password",  to: "passwords#reset"
  end

  namespace :api do
    namespace :v1 do
      # Webhooks
      namespace :webhooks do
        post "evolution", to: "evolution#receive"
      end

      get   "me", to: "users#me"
      patch "me", to: "users#update_me"

      resources :workspaces, only: [:index, :show, :create, :update] do
        member do
          post :invite
          post :accept_invite
        end
      end

      resources :pipelines, only: [:index, :show, :create, :update, :destroy] do
        collection { post :reorder }

        resources :stages, only: [:index, :create, :update, :destroy],
                           controller: "pipelines/stages" do
          collection { post :reorder }
        end

        resources :cards, only: [:index, :show, :create, :update, :destroy],
                          controller: "pipelines/cards" do
          member do
            post :move
            post :archive
          end
        end

        resources :automations, only: [:index, :show, :create, :update, :destroy],
                                controller: "pipelines/automations" do
          member do
            post :toggle
            get  :logs
          end
          collection do
            get :available_fields
          end
        end

        get "cards/:card_id/timeline",
            to:  "pipelines/card_events#timeline",
            as:  :card_timeline

        get   "cards/:card_id/custom_fields",
              to:  "pipelines/card_custom_fields#show",
              as:  :card_custom_fields
        patch "cards/:card_id/custom_fields",
              to:  "pipelines/card_custom_fields#update"
      end

      resources :cards, only: [] do
        resources :messages, only: [:create], controller: "cards/messages"
      end

      resources :contacts, only: [:index, :show] do
        collection do
          get :search
        end
      end

      resources :broadcasts, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :schedule
          post :send_now
          post :cancel
          get  :report
        end
        collection do
          get :preview
        end
      end

      resources :custom_fields, only: [:index, :show, :create, :update, :destroy],
                                controller: "custom_fields"

      namespace :whatsapp do
        post   "connect",                  to: "connections#connect"
        get    "status",                   to: "connections#status"
        post   "disconnect",               to: "connections#disconnect"
        delete "destroy",                  to: "connections#destroy"
        patch  "instances/:instance_id",   to: "connections#update"
      end

      get  "conversations",     to: "conversations#index"

      get  "dashboard",        to: "dashboard#index"
      get  "dashboard/funnel", to: "dashboard#funnel"
      get  "dashboard/agents", to: "dashboard#agents"
    end
  end
end
