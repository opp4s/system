class StagePolicy < ApplicationPolicy
  def index?   = member?
  def show?    = member?
  def create?  = owner_or_admin?
  def update?  = owner_or_admin?
  def destroy? = owner_or_admin?
  def reorder? = owner_or_admin?
end
