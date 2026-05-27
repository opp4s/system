class AddLossReasonsToFunnelStages < ActiveRecord::Migration[7.1]
  def change
    add_column :funnel_stages, :loss_reasons, :jsonb, default: []
  end
end
