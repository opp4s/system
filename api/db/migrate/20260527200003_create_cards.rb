class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.references :pipeline,         null: false, foreign_key: true
      t.references :stage,            null: false, foreign_key: true
      t.references :workspace,        null: false, foreign_key: true
      t.bigint     :assigned_agent_id
      t.bigint     :assigned_team_id
      t.string     :title,            null: false
      t.decimal    :value,            precision: 15, scale: 2, default: 0
      t.string     :currency,         default: "BRL"
      t.text       :lost_reason
      t.string     :contact_name
      t.string     :contact_phone
      t.string     :contact_email
      t.jsonb      :custom_fields,    default: {}
      t.datetime   :stage_changed_at
      t.datetime   :archived_at

      t.timestamps
    end

    add_index :cards, :assigned_agent_id
    add_index :cards, :archived_at
    add_index :cards, [:stage_id, :archived_at], name: "idx_cards_stage_active"
    add_index :cards, :custom_fields, using: :gin
  end
end
