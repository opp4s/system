module Funnels
  class StagePolicy
    attr_reader :user, :stage

    def initialize(user, stage)
      @user = user
      @stage = stage
    end

    def index?
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

    def reorder?
      admin?
    end

    private

    def account_id
      stage.funnel.account_id
    end

    def user_in_account?
      user.account_users.exists?(account_id: account_id)
    end

    def admin?
      user.account_users.exists?(account_id: account_id, role: :administrator)
    end
  end
end
