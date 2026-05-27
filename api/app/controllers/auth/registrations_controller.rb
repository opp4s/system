module Auth
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_user!

    # POST /auth/register
    def create
      user = User.new(registration_params)

      if user.save
        token = encode_jwt(user)
        render json: {
          data: user_payload(user),
          token: token
        }, status: :created
      else
        render_unprocessable(user)
      end
    end

    private

    def registration_params
      params.require(:user).permit(:email, :password, :password_confirmation, :name)
    end

    def encode_jwt(user)
      Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    end

    def user_payload(user)
      {
        id: user.id,
        email: user.email,
        name: user.name,
        avatar_url: user.avatar_url,
        created_at: user.created_at
      }
    end
  end
end
