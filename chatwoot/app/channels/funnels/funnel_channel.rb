module Funnels
  class FunnelChannel < ApplicationCable::Channel
    def subscribed
      funnel = current_funnel_user_account
                 &.funnels&.find_by(id: params[:funnel_id])
      if funnel
        stream_from "funnel_#{funnel.id}"
        Rails.logger.info "[funnels] #{current_funnel_user&.name} subscribed to funnel_#{funnel.id}"
      else
        reject
      end
    end

    def unsubscribed
      stop_all_streams
    end

    private

    # Replica o padrão do RoomChannel do Chatwoot:
    # frontend passa pubsub_token + user_id + account_id como params do canal.
    def current_funnel_user
      @current_funnel_user ||= User.find_by!(
        pubsub_token: params[:pubsub_token],
        id: params[:user_id]
      )
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def current_funnel_user_account
      return nil unless current_funnel_user

      @current_funnel_user_account ||= current_funnel_user
                                         .accounts
                                         .find_by(id: params[:account_id])
    end
  end
end
