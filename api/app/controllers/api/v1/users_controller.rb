module Api
  module V1
    class UsersController < ApplicationController
      # GET /api/v1/me
      def me
        authorize current_user, :show?, policy_class: UserPolicy
        render json: { data: me_payload(current_user) }, status: :ok
      end

      # PATCH /api/v1/me
      def update_me
        authorize current_user, :update?, policy_class: UserPolicy

        if me_params[:password].present?
          # Devise exige current_password para troca de senha
          unless current_user.valid_password?(me_params[:current_password])
            return render json: { error: "Senha atual incorreta" }, status: :unprocessable_entity
          end

          unless current_user.update(
            password:              me_params[:password],
            password_confirmation: me_params[:password_confirmation]
          )
            return render_unprocessable(current_user)
          end
        else
          unless current_user.update(me_params.except(:current_password, :password, :password_confirmation))
            return render_unprocessable(current_user)
          end
        end

        render json: { data: me_payload(current_user) }, status: :ok
      end

      private

      def me_params
        params.require(:user).permit(
          :name,
          :avatar_url,
          :current_password,
          :password,
          :password_confirmation
        )
      end

      def me_payload(user)
        {
          id:            user.id,
          email:         user.email,
          name:          user.name,
          avatar_url:    user.avatar_url,
          pubsub_token:  user.pubsub_token,
          created_at:    user.created_at,
          updated_at:    user.updated_at,
          workspaces:    user_workspaces(user)
        }
      end

      def user_workspaces(user)
        user.workspace_memberships
            .accepted
            .includes(:workspace)
            .map do |m|
          {
            id:       m.workspace.id,
            name:     m.workspace.name,
            slug:     m.workspace.slug,
            plan:     m.workspace.plan,
            role:     m.role,
            owner_id: m.workspace.owner_id
          }
        end
      end
    end
  end
end
