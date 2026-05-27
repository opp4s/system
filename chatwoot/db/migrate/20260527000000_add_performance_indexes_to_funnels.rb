class AddPerformanceIndexesToFunnels < ActiveRecord::Migration[7.1]
  def change
    # Query mais frequente: cards ativos por etapa
    add_index :funnel_cards, [:funnel_stage_id, :archived_at], name: 'idx_funnel_cards_stage_active'
    # Cards por funil (para listagem)
    add_index :funnel_cards, [:funnel_id, :archived_at], name: 'idx_funnel_cards_funnel_active'
  end
end
