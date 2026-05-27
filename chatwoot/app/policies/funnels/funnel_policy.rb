module Funnels
  class FunnelPolicy
    attr_reader :user, :funnel

    def initialize(user, funnel)
      @user = user
      @funnel = funnel
    end

    def index?
      user_in_account?
    end

    def show?
      user_in_account?
    end

    def create?
      admin?
    end

    def update?
      admin?
    end

    def destroy?
      admin?
    end

    def analytics?
      user_in_account?
    end

    private

    def user_in_account?
      user.account_users.exists?(account_id: funnel.account_id)
    end

    def admin?
      user.account_users.exists?(account_id: funnel.account_id, role: :administrator)
    end
  end
end
