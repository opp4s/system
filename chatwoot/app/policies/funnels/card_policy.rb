module Funnels
  class CardPolicy
    attr_reader :user, :card

    def initialize(user, card)
      @user = user
      @card = card
    end

    def show?
      user_in_account?
    end

    def create?
      user_in_account?
    end

    def update?
      user_in_account?
    end

    def destroy?
      admin?
    end

    def move?
      user_in_account?
    end

    def transfer?
      admin?
    end

    def archive?
      user_in_account?
    end

    def timeline?
      user_in_account?
    end

    def link_conversation?
      user_in_account?
    end

    def unlink_conversation?
      user_in_account?
    end

    private

    def user_in_account?
      user.account_users.exists?(account_id: card.account_id)
    end

    def admin?
      user.account_users.exists?(account_id: card.account_id, role: :administrator)
    end
  end
end
