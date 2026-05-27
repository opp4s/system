module Funnels
  module Api
    class BaseController < ::Api::V1::BaseController
      before_action :set_account
      before_action :check_authorization

      private

      def set_account
        @account = Account.find(params[:account_id])
      end

      def check_authorization
        raise Pundit::NotAuthorizedError unless current_user&.account_users
                                                              &.exists?(account: @account)
      end

      def pundit_user
        current_user
      end
    end
  end
end
