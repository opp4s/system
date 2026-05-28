module Api
  module V1
    class BroadcastsController < ApplicationController
      before_action :require_workspace!
      before_action :set_broadcast, only: [:show, :update, :destroy, :schedule,
                                           :send_now, :cancel, :report, :preview]

      # GET /api/v1/broadcasts
      def index
        authorize Broadcast.new(workspace: current_workspace), :index?
        broadcasts = current_workspace.broadcasts.recent
        render json: { data: broadcasts.map { |b| broadcast_payload(b) } }
      end

      # GET /api/v1/broadcasts/:id
      def show
        authorize @broadcast
        render json: { data: broadcast_payload(@broadcast) }
      end

      # POST /api/v1/broadcasts
      def create
        authorize Broadcast.new(workspace: current_workspace), :create?
        broadcast = current_workspace.broadcasts.build(broadcast_params)
        broadcast.created_by = current_user
        if broadcast.save
          render json: { data: broadcast_payload(broadcast) }, status: :created
        else
          render_unprocessable(broadcast)
        end
      end

      # PATCH /api/v1/broadcasts/:id
      def update
        authorize @broadcast
        return render json: { error: "Não é possível editar broadcast em status #{@broadcast.status}" },
                      status: :unprocessable_entity unless @broadcast.editable?
        if @broadcast.update(broadcast_params)
          render json: { data: broadcast_payload(@broadcast) }
        else
          render_unprocessable(@broadcast)
        end
      end

      # DELETE /api/v1/broadcasts/:id
      def destroy
        authorize @broadcast
        return render json: { error: "Só broadcasts em rascunho podem ser deletados" },
                      status: :unprocessable_entity unless @broadcast.editable?
        @broadcast.destroy
        head :no_content
      end

      # POST /api/v1/broadcasts/:id/schedule
      def schedule
        authorize @broadcast, :schedule?
        return render json: { error: "Broadcast já foi enviado ou cancelado" },
                      status: :unprocessable_entity unless @broadcast.draft?

        scheduled_at = params[:scheduled_at] ? Time.zone.parse(params[:scheduled_at]) : 1.minute.from_now
        contacts = Broadcasts::AudienceResolver.new(@broadcast).resolve

        if contacts.empty?
          return render json: { error: "Nenhum contato encontrado para os filtros informados" },
                        status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          contacts.find_each do |contact|
            BroadcastMessage.find_or_create_by!(broadcast: @broadcast, contact: contact)
          end
          @broadcast.update!(
            status: "scheduled",
            scheduled_at: scheduled_at,
            total_recipients: contacts.count
          )
        end

        Broadcasts::ExecuteJob.set(wait_until: scheduled_at).perform_later(@broadcast.id)
        render json: { data: broadcast_payload(@broadcast) }
      end

      # POST /api/v1/broadcasts/:id/send_now
      def send_now
        authorize @broadcast, :send_now?
        return render json: { error: "Broadcast já foi enviado ou cancelado" },
                      status: :unprocessable_entity unless @broadcast.draft?

        contacts = Broadcasts::AudienceResolver.new(@broadcast).resolve
        if contacts.empty?
          return render json: { error: "Nenhum contato encontrado para os filtros informados" },
                        status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          contacts.find_each do |contact|
            BroadcastMessage.find_or_create_by!(broadcast: @broadcast, contact: contact)
          end
          @broadcast.update!(
            status: "scheduled",
            scheduled_at: Time.current,
            total_recipients: contacts.count
          )
        end

        Broadcasts::ExecuteJob.perform_later(@broadcast.id)
        render json: { data: broadcast_payload(@broadcast) }
      end

      # POST /api/v1/broadcasts/:id/cancel
      def cancel
        authorize @broadcast, :cancel?
        return render json: { error: "Broadcast não pode ser cancelado no status '#{@broadcast.status}'" },
                      status: :unprocessable_entity unless @broadcast.cancellable?
        @broadcast.update!(status: "cancelled", completed_at: Time.current)
        render json: { data: broadcast_payload(@broadcast) }
      end

      # GET /api/v1/broadcasts/:id/report
      def report
        authorize @broadcast, :report?
        failures = @broadcast.broadcast_messages.failed.includes(:contact).map do |bm|
          { contact_name: bm.contact.name, phone: bm.contact.phone_number, error: bm.error_message }
        end
        duration_mins = if @broadcast.started_at && @broadcast.completed_at
                          ((@broadcast.completed_at - @broadcast.started_at) / 60).round(1)
                        end
        render json: {
          data: {
            id:               @broadcast.id,
            name:             @broadcast.name,
            status:           @broadcast.status,
            total_recipients: @broadcast.total_recipients,
            sent_count:       @broadcast.sent_count,
            failed_count:     @broadcast.failed_count,
            delivery_rate:    @broadcast.delivery_rate,
            started_at:       @broadcast.started_at,
            completed_at:     @broadcast.completed_at,
            duration_minutes: duration_mins,
            failures:         failures
          }
        }
      end

      # GET /api/v1/broadcasts/:id/preview
      def preview
        authorize @broadcast, :preview?
        contacts = Broadcasts::AudienceResolver.new(@broadcast).resolve.limit(5)
        examples = contacts.map do |c|
          {
            contact_name:  c.name,
            phone:         c.phone_number,
            message_preview: Broadcasts::ExecuteJob.new.send(:interpolate, @broadcast.message, c)
          }
        end
        render json: {
          data: {
            audience_count: Broadcasts::AudienceResolver.new(@broadcast).count,
            examples: examples
          }
        }
      end

      private

      def set_broadcast
        @broadcast = current_workspace.broadcasts.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Broadcast não encontrado" }, status: :not_found
      end

      def broadcast_params
        params.require(:broadcast).permit(
          :name, :message, :media_url, :media_type, :pipeline_id, :scheduled_at,
          audience_filters: {}
        )
      end

      def broadcast_payload(broadcast)
        {
          id:               broadcast.id,
          name:             broadcast.name,
          message:          broadcast.message,
          status:           broadcast.status,
          total_recipients: broadcast.total_recipients,
          sent_count:       broadcast.sent_count,
          failed_count:     broadcast.failed_count,
          delivery_rate:    broadcast.delivery_rate,
          audience_filters: broadcast.audience_filters,
          scheduled_at:     broadcast.scheduled_at,
          started_at:       broadcast.started_at,
          completed_at:     broadcast.completed_at,
          created_at:       broadcast.created_at
        }
      end
    end
  end
end
