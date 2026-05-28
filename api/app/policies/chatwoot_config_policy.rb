class ChatwootConfigPolicy < ApplicationPolicy
  def show?      = owner_or_admin?
  def configure? = owner_or_admin?
end
