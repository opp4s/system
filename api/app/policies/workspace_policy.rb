class WorkspacePolicy < ApplicationPolicy
  # Qualquer usuário autenticado pode criar um workspace
  def create? = current_user.present?

  # Para show/update/invite o membership é verificado no record (não no header)
  def show?   = membership_on_record.present?
  def update? = %w[owner admin].include?(membership_on_record&.role)
  def invite? = %w[owner admin].include?(membership_on_record&.role)

  def accept_invite?
    WorkspaceMembership.exists?(
      workspace:   record,
      user:        current_user,
      accepted_at: nil
    )
  end

  class Scope < ApplicationPolicy::Scope
    # Retorna workspaces onde o usuário é membro aceito
    def resolve
      scope
        .joins(:workspace_memberships)
        .where(workspace_memberships: { user_id: current_user.id })
        .where.not(workspace_memberships: { accepted_at: nil })
    end
  end

  private

  def membership_on_record
    @membership_on_record ||= WorkspaceMembership.find_by(
      workspace: record,
      user:      current_user
    )
  end
end
