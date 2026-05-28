class ContactPolicy < ApplicationPolicy
  def index?  = member?
  def show?   = member?
  def search? = member?
  def sync?   = owner_or_admin?
end
