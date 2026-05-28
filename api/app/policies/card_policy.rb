class CardPolicy < ApplicationPolicy
  def index?   = member?
  def show?    = member?
  def create?  = member?
  def update?  = member?
  def destroy? = owner_or_admin?
  def move?    = member?
  def archive? = member?
end
