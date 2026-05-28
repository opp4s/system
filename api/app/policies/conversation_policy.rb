class ConversationPolicy < ApplicationPolicy
  def show?         = member?
  def index?        = member?
  def send_message? = member?
end
