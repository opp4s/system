module Auth
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:create]
    skip_before_action :resolve_current_workspace

    # POST /auth/login
    def create
      user = User.find_by(email: login_params[:email]&.downcase)

      if user&.valid_password?(login_params[:password])
        token = encode_jwt(user)
        render json: {
          data: user_payload(user),
          token: token
        }, status: :ok
      else
        render json: { error: "Email ou senha inválidos" }, status: :unauthorized
      end
    end

    # DELETE /auth/logout
    def destroy
      # JTIMatcher revoga o token ao rotacionar o jti
      current_user.update!(jti: SecureRandom.uuid)
      render json: { data: { message: "Logout realizado com sucesso" } }, status: :ok
    end

    private

    def login_params
      params.require(:user).permit(:email, :password)
    end

    def encode_jwt(user)
      Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    end

    def user_payload(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar_url: user.avatar_url
      }
    end
  end
end
