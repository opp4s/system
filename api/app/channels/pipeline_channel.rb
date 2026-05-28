class PipelineChannel < ApplicationCable::Channel
  def subscribed
    pipeline = accessible_pipeline(params[:pipeline_id])
    if pipeline
      stream_from "pipeline_#{pipeline.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def accessible_pipeline(pipeline_id)
    return nil unless pipeline_id.present?

    Pipeline.joins(workspace: :workspace_memberships)
            .where(workspace_memberships: { user: current_user })
            .where.not(workspace_memberships: { accepted_at: nil })
            .find_by(id: pipeline_id)
  end
end
