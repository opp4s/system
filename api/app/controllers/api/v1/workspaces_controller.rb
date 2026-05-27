module Api
  module V1
    class WorkspacesController < ApplicationController
      before_action :set_workspace, only: [:show, :update, :invite, :accept_invite]

      # GET /api/v1/workspaces
      def index
        workspaces = current_user.workspace_memberships
                                 .accepted
                                 .includes(:workspace)
                                 .map do |m|
          workspace_payload(m.workspace, m)
        end

        render json: { data: workspaces }, status: :ok
      end

      # GET /api/v1/workspaces/:id
      def show
        membership = WorkspaceMembership.find_by!(workspace: @workspace, user: current_user)
        render json: { data: workspace_payload(@workspace, membership) }, status: :ok
      end

      # POST /api/v1/workspaces
      def create
        workspace = Workspace.new(workspace_params.merge(owner: current_user))

        if workspace.save
          membership = WorkspaceMembership.create!(
            workspace:   workspace,
            user:        current_user,
            role:        "owner",
            accepted_at: Time.current,
            invited_at:  Time.current
          )
          render json: { data: workspace_payload(workspace, membership) }, status: :created
        else
          render_unprocessable(workspace)
        end
      end

      # PATCH /api/v1/workspaces/:id
      def update
        membership = WorkspaceMembership.find_by!(workspace: @workspace, user: current_user)

        unless %w[owner admin].include?(membership.role)
          return render json: { error: "Acesso não autorizado" }, status: :forbidden
        end

        if @workspace.update(workspace_params)
          render json: { data: workspace_payload(@workspace, membership) }, status: :ok
        else
          render_unprocessable(@workspace)
        end
      end

      # POST /api/v1/workspaces/:id/invite
      def invite
        membership = WorkspaceMembership.find_by!(workspace: @workspace, user: current_user)

        unless %w[owner admin].include?(membership.role)
          return render json: { error: "Acesso não autorizado" }, status: :forbidden
        end

        invitee = User.find_by(email: invite_params[:email]&.downcase)
        return render json: { error: "Usuário não encontrado" }, status: :not_found unless invitee

        if WorkspaceMembership.exists?(workspace: @workspace, user: invitee)
          return render json: { error: "Usuário já é membro deste workspace" }, status: :unprocessable_entity
        end

        new_membership = WorkspaceMembership.create!(
          workspace:  @workspace,
          user:       invitee,
          role:       invite_params.fetch(:role, "agent"),
          invited_at: Time.current
        )

        render json: {
          data: {
            user_id:    invitee.id,
            email:      invitee.email,
            name:       invitee.name,
            role:       new_membership.role,
            invited_at: new_membership.invited_at
          }
        }, status: :created
      end

      # POST /api/v1/workspaces/:id/accept_invite
      def accept_invite
        membership = WorkspaceMembership.find_by(workspace: @workspace, user: current_user)

        return render json: { error: "Convite não encontrado" }, status: :not_found unless membership
        return render json: { error: "Convite já aceito" }, status: :unprocessable_entity if membership.accepted_at?

        membership.update!(accepted_at: Time.current)
        render json: { data: workspace_payload(@workspace, membership) }, status: :ok
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:id])

        unless WorkspaceMembership.exists?(workspace: @workspace, user: current_user)
          render json: { error: "Workspace não encontrado ou acesso negado" }, status: :forbidden
        end
      end

      def workspace_params
        params.require(:workspace).permit(:name, :slug, :plan, settings: {})
      end

      def invite_params
        params.require(:invite).permit(:email, :role)
      end

      def workspace_payload(workspace, membership)
        {
          id:         workspace.id,
          name:       workspace.name,
          slug:       workspace.slug,
          plan:       workspace.plan,
          settings:   workspace.settings,
          role:       membership.role,
          owner_id:   workspace.owner_id,
          created_at: workspace.created_at,
          updated_at: workspace.updated_at
        }
      end
    end
  end
end
