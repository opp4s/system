module Auth
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :resolve_current_workspace

    # POST /auth/register
    def create
      user = User.new(registration_params)

      if user.save
        workspace = create_default_workspace(user)
        token     = encode_jwt(user)
        render json: {
          data: user_payload(user, workspace),
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

    def create_default_workspace(user)
      workspace = Workspace.create!(
        name:  "#{user.name}'s Workspace",
        owner: user
      )
      WorkspaceMembership.create!(
        workspace:   workspace,
        user:        user,
        role:        "owner",
        accepted_at: Time.current,
        invited_at:  Time.current
      )
      workspace
    end

    def encode_jwt(user)
      Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
    end

    def user_payload(user, workspace = nil)
      payload = {
        id:            user.id,
        email:         user.email,
        name:          user.name,
        avatar_url:    user.avatar_url,
        pubsub_token:  user.pubsub_token,
        created_at:    user.created_at
      }
      if workspace
        payload[:workspace] = {
          id:   workspace.id,
          name: workspace.name,
          slug: workspace.slug,
          plan: workspace.plan
        }
      end
      payload
    end
  end
end
