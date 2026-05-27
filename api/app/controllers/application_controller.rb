class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include WorkspaceResolvable

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_forbidden
    render json: { error: "Acesso não autorizado" }, status: :forbidden
  end

  def render_not_found
    render json: { error: "Recurso não encontrado" }, status: :not_found
  end

  def render_unprocessable(resource)
    render json: {
      error: resource.errors.full_messages.first,
      details: resource.errors.messages
    }, status: :unprocessable_entity
  end
end
