Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

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
      resources :workspaces, only: [:index, :show, :create, :update] do
        member do
          post :invite
          post :accept_invite
        end
      end
    end
  end
end
