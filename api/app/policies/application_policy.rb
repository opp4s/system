# Base Pundit policy.
#
# `user` recebe um UserContext (não o model User diretamente) para
# que as policies também tenham acesso ao current_workspace e ao role
# do usuário nesse workspace — evitando N queries repetidas.
#
# Uso nos controllers:
#   authorize @record                        # usa current_user diretamente
#   authorize @record, policy_class: WorkspacePolicy
#
# O ApplicationController sobrescreve `pundit_user` para retornar um
# UserContext em vez do User puro.

class ApplicationPolicy
  attr_reader :context, :record

  # Contexto passado ao Pundit em vez do User bruto
  UserContext = Data.define(:user, :workspace, :membership)

  def initialize(context, record)
    @context = context
    @record  = record
  end

  # Atalhos de conveniência
  def current_user       = context.user
  def current_workspace  = context.workspace
  def current_membership = context.membership

  # Role helpers
  def owner?  = current_membership&.role == "owner"
  def admin?  = current_membership&.role == "admin"
  def agent?  = current_membership&.role == "agent"
  def owner_or_admin? = owner? || admin?
  def member? = current_membership.present?

  # Padrão: negar tudo (explicitamente liberado em cada subpolicy)
  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false

  class Scope
    def initialize(context, scope)
      @context = context
      @scope   = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class}#resolve não implementado"
    end

    private

    attr_reader :context, :scope

    def current_user       = context.user
    def current_workspace  = context.workspace
    def current_membership = context.membership
  end
end
