module Funnels
  class FunnelCardChannel < ApplicationCable::Channel
    def subscribed
      user    = resolve_user
      account = resolve_account(user)
      card    = account&.then { Funnels::Card.active.find_by(id: params[:card_id], account_id: account.id) }

      if card
        stream_from "funnel_card_#{card.id}"
        Rails.logger.info "[funnels] #{user&.name} subscribed to funnel_card_#{card.id}"
      else
        reject
      end
    end

    def unsubscribed
      stop_all_streams
    end

    private

    def resolve_user
      User.find_by!(pubsub_token: params[:pubsub_token], id: params[:user_id])
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def resolve_account(user)
      user&.accounts&.find_by(id: params[:account_id])
    end
  end
end
