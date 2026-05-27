module WorkspaceResolvable
  extend ActiveSupport::Concern

  included do
    before_action :resolve_current_workspace
  end

  private

  def current_workspace
    @current_workspace
  end

  def resolve_current_workspace
    workspace_id = request.headers["X-Workspace-Id"]

    if workspace_id.present?
      @current_workspace = current_user
                             .workspace_memberships
                             .accepted
                             .joins(:workspace)
                             .where(workspaces: { id: workspace_id })
                             .first
                             &.workspace

      unless @current_workspace
        render json: { error: "Workspace não encontrado ou acesso negado" }, status: :forbidden and return
      end
    end
  end

  def require_workspace!
    unless current_workspace
      render json: { error: "Header X-Workspace-Id é obrigatório" }, status: :bad_request
    end
  end

  def current_membership
    return nil unless current_workspace && current_user

    @current_membership ||= WorkspaceMembership.find_by(
      workspace: current_workspace,
      user: current_user
    )
  end
end
