module Auth
  class PasswordsController < ApplicationController
    skip_before_action :authenticate_user!

    # POST /auth/forgot_password
    def forgot
      user = User.find_by(email: params[:email]&.downcase)

      # Sempre retorna 200 para não vazar existência de emails
      if user
        user.send_reset_password_instructions
      end

      render json: {
        data: { message: "Se o email existir, você receberá as instruções em breve" }
      }, status: :ok
    end

    # POST /auth/reset_password
    def reset
      user = User.reset_password_by_token(reset_params)

      if user.errors.empty?
        render json: {
          data: { message: "Senha redefinida com sucesso" }
        }, status: :ok
      else
        render_unprocessable(user)
      end
    end

    private

    def reset_params
      params.permit(:reset_password_token, :password, :password_confirmation)
    end
  end
end
