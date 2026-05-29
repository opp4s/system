class BroadcastPolicy < ApplicationPolicy
  def index?   = member?
  def show?    = member?
  def create?  = member?
  def update?  = owner_or_admin?
  def destroy? = owner_or_admin?
  def schedule?   = owner_or_admin?
  def send_now?   = owner_or_admin?
  def cancel?     = owner_or_admin?
  def report?     = member?
  def preview?    = member?
end
