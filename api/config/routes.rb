Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => "/cable"

  # Cria o mapping Warden (:user) sem gerar as rotas padrão do Devise
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
      # Webhooks — sem autenticação JWT (identificação via account_id no payload)
      namespace :webhooks do
        post "chatwoot", to: "chatwoot#receive"
      end

      # Perfil do usuário autenticado
      get   "me", to: "users#me"
      patch "me", to: "users#update_me"

      resources :workspaces, only: [:index, :show, :create, :update] do
        member do
          post :invite
          post :accept_invite
        end
      end

      # Pipelines Kanban
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

        # Timeline de eventos do card
        get "cards/:card_id/timeline",
            to:  "pipelines/card_events#timeline",
            as:  :card_timeline

        # Custom fields dedicado (merge semântico)
        get   "cards/:card_id/custom_fields",
              to:  "pipelines/card_custom_fields#show",
              as:  :card_custom_fields
        patch "cards/:card_id/custom_fields",
              to:  "pipelines/card_custom_fields#update"
      end

      # Envio de mensagens via card (busca conversa vinculada)
      resources :cards, only: [] do
        resources :messages, only: [:create], controller: "cards/messages"
      end

      # Envio de mensagens via conversa Chatwoot diretamente
      resources :conversations, only: [] do
        resources :messages, only: [:create], controller: "conversations/messages"
      end

      # Contatos (espelho Chatwoot)
      resources :contacts, only: [:index, :show] do
        collection do
          get  :search
          post :sync
        end
      end

      # Integração Chatwoot
      namespace :chatwoot do
        get  "status",    to: "configs#status"
        post "configure", to: "configs#configure"
      end
    end
  end
end
