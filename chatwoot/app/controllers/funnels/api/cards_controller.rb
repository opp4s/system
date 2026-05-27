module Funnels
  module Api
    class CardsController < BaseController
      before_action :set_funnel, except: [:by_conversation]
      before_action :set_card, only: %i[show update destroy move transfer archive timeline link_conversation unlink_conversation]

      def index
        cards = @funnel.cards.active
                       .includes(:stage, :assigned_agent, :assigned_team,
                                 card_conversations: { conversation: :contact })
        cards = cards.in_stage(params[:stage_id]) if params[:stage_id].present?
        cards = cards.where(assigned_agent_id: params[:agent_id]) if params[:agent_id].present?
        render json: cards.map { |c| Funnels::Broadcaster.card_payload(c)[:card] }
      end

      def show
        render json: card_json_detailed(@card)
      end

      def create
        card = @funnel.cards.build(card_params.merge(
          account_id:      @account.id,
          funnel_stage_id: params.dig(:card, :stage_id),
          stage_changed_at: Time.current
        ))

        if card.save
          card.record_event('card_created', user: current_user)
          invalidate_stage_cache(card.funnel_stage_id)
          Funnels::Broadcaster.card_event(card, 'card_created')
          render json: Funnels::Broadcaster.card_payload(card)[:card], status: :created
        else
          render json: { errors: card.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        old_stage_id = @card.funnel_stage_id
        if @card.update(card_params)
          @card.record_event('card_updated', user: current_user)
          invalidate_stage_cache(old_stage_id)
          invalidate_stage_cache(@card.funnel_stage_id)
          Funnels::Broadcaster.card_event(@card, 'card_updated')
          render json: Funnels::Broadcaster.card_payload(@card)[:card]
        else
          render json: { errors: @card.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        stage_id = @card.funnel_stage_id
        card_id  = @card.id
        funnel_id = @card.funnel_id
        @card.destroy
        invalidate_stage_cache(stage_id)
        # Broadcast direto pois card já não existe
        ActionCable.server.broadcast("funnel_#{funnel_id}", { event: 'card_deleted', card: { id: card_id } })
        ActionCable.server.broadcast("funnel_card_#{card_id}", { event: 'card_deleted', card: { id: card_id } })
        head :no_content
      end

      def move
        from_stage_id = @card.funnel_stage_id
        stage = @funnel.stages.find(params.require(:stage_id))

        @card.move_to_stage!(stage, user: current_user, reason: params[:lost_reason])

        invalidate_stage_cache(from_stage_id)
        invalidate_stage_cache(stage.id)

        Funnels::Broadcaster.card_event(@card, 'card_moved',
          extra: { from_stage_id: from_stage_id, to_stage_id: stage.id })
        Funnels::Broadcaster.stage_updated(stage)

        render json: Funnels::Broadcaster.card_payload(@card)[:card]
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Etapa não encontrada' }, status: :not_found
      end

      def transfer
        target_funnel = @account.funnels.find(params.require(:funnel_id))
        target_stage  = target_funnel.stages.find(params.require(:stage_id))
        old_funnel_id = @card.funnel_id
        old_stage_id  = @card.funnel_stage_id

        @card.move_to_stage!(target_stage, user: current_user)
        @card.update!(funnel_id: target_funnel.id)
        @card.record_event('funnel_transferred', user: current_user, payload: {
          from_funnel_id: old_funnel_id,
          to_funnel_id:   target_funnel.id,
          to_stage_id:    target_stage.id
        })

        invalidate_stage_cache(old_stage_id)
        invalidate_stage_cache(target_stage.id)

        # Notifica funil de origem (remoção) e de destino (adição)
        ActionCable.server.broadcast("funnel_#{old_funnel_id}",
          { event: 'card_deleted', card: { id: @card.id } })
        Funnels::Broadcaster.card_event(@card, 'card_transferred')

        render json: Funnels::Broadcaster.card_payload(@card)[:card]
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil ou etapa não encontrada' }, status: :not_found
      end

      def archive
        stage_id = @card.funnel_stage_id
        @card.archive!(user: current_user)
        invalidate_stage_cache(stage_id)
        Funnels::Broadcaster.card_event(@card, 'card_archived')
        head :no_content
      end

      def timeline
        messages = []
        @card.conversations.each do |conv|
          messages += conv.messages.order(:created_at).limit(50).map do |m|
            { type: 'message', id: m.id, content: m.content,
              created_at: m.created_at, sender: m.sender&.name }
          end
        end

        events = @card.card_events.recent.limit(50).map do |e|
          { type: 'event', id: e.id, event_type: e.event_type,
            payload: e.payload, created_at: e.created_at,
            user: e.user&.name }
        end

        timeline = (messages + events).sort_by { |i| i[:created_at] }.reverse
        render json: { timeline: timeline }

      def link_conversation

      def by_conversation
        conversation_id = params.require(:conversation_id)
        card_ids = Funnels::CardConversation
                     .where(conversation_id: conversation_id)
                     .pluck(:funnel_card_id)

        cards = Funnels::Card.where(id: card_ids, account_id: @account.id)
                             .includes(:stage, :funnel)

        render json: cards.map { |c|
          {
            id:         c.id,
            title:      c.title,
            funnel_id:  c.funnel_id,
            funnel_name: c.funnel.name,
            stage_id:   c.funnel_stage_id,
            stage_name: c.stage.name,
            stage_color: c.stage.color,
            value:      c.value.to_f,
            days_in_stage: c.days_in_stage
          }
        }
      end
        conversation = @account.conversations.find(params.require(:conversation_id))
        cc = @card.card_conversations.find_or_initialize_by(conversation_id: conversation.id)
        is_first = @card.card_conversations.count.zero?
        cc.is_primary = is_first unless cc.persisted?
        cc.save!
        @card.record_event('conversation_linked', user: current_user, payload: { conversation_id: conversation.id })
        Funnels::Broadcaster.card_event(@card, 'card_updated')
        render json: { id: cc.id, conversation_id: cc.conversation_id, is_primary: cc.is_primary }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Conversa não encontrada' }, status: :not_found
      end

      def unlink_conversation
        cc = @card.card_conversations.find_by!(conversation_id: params.require(:conversation_id))
        cc.destroy
        @card.record_event('conversation_unlinked', user: current_user, payload: { conversation_id: params[:conversation_id].to_i })
        Funnels::Broadcaster.card_event(@card, 'card_updated')
        head :no_content
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Vínculo não encontrado' }, status: :not_found
      end
      end

      private

      def set_funnel
        @funnel = @account.funnels.find(params[:funnel_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Funil não encontrado' }, status: :not_found
      end

      def set_card
        @card = @funnel.cards.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Card não encontrado' }, status: :not_found
      end

      def card_params
        params.require(:card).permit(
          :title, :value, :currency, :lost_reason,
          :assigned_agent_id, :assigned_team_id, :funnel_stage_id
        )
      end

      # Usado apenas no show — inclui conversas e campos customizados
      def card_json_detailed(card)
        base = Funnels::Broadcaster.card_payload(card)[:card]
        base.merge(
          conversations: card.card_conversations.map { |cc|
            { id: cc.conversation_id, is_primary: cc.is_primary }
          },
          custom_fields: card.custom_field_values.map { |cfv|
            { attribute_id:   cfv.custom_attribute_id,
              attribute_name: cfv.custom_attribute.attribute_display_name,
              value:          cfv.value }
          }
        )
      end

      def invalidate_stage_cache(stage_id)
        Rails.cache.delete("funnels:stage_counts:#{stage_id}")
      end
    end
  end
end
