class PipelinePolicy < ApplicationPolicy
  def index?   = member?
  def show?    = member?
  def create?  = owner_or_admin?
  def update?  = owner_or_admin?
  def destroy? = owner?
  def reorder? = owner_or_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(workspace: current_workspace)
    end
  end
end
