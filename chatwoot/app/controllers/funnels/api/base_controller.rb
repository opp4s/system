module Funnels
  module Api
    class BaseController < ::Api::V1::Accounts::BaseController
      before_action :set_account

      private

      # current_account é resolvido pelo Chatwoot BaseController via params[:account_id]
      # @account é o alias usado pelos controllers do plugin
      def set_account
        @account = current_account
      end
    end
  end
end
