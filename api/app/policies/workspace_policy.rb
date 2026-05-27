class WorkspacePolicy < ApplicationPolicy
  # Qualquer usuário autenticado pode criar um workspace
  def create? = current_user.present?

  # Apenas membros aceitos podem ver
  def show?   = member?

  # Apenas owner ou admin podem editar
  def update? = owner_or_admin?

  # Apenas owner ou admin podem convidar
  def invite? = owner_or_admin?

  # Qualquer membro com convite pendente pode aceitar
  def accept_invite?
    WorkspaceMembership.exists?(
      workspace: record,
      user:      current_user,
      accepted_at: nil
    )
  end

  class Scope < ApplicationPolicy::Scope
    # Retorna workspaces onde o usuário é membro aceito
    def resolve
      scope
        .joins(:workspace_memberships)
        .where(
          workspace_memberships: {
            user_id:     current_user.id,
            accepted_at: ..Time.current   # accepted_at IS NOT NULL e <= agora
          }
        )
    end
  end
end
