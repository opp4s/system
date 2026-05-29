class UserPolicy < ApplicationPolicy
  # Apenas o próprio usuário pode ver/editar seu perfil
  def show?   = current_user == record
  def update? = current_user == record
end
