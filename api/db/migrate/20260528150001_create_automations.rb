class CreateAutomations < ActiveRecord::Migration[7.1]
  def change
    create_table :automations do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :pipeline, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :description
      t.boolean :active, default: true
      t.integer :position, default: 0
      t.string  :trigger_type, null: false
      t.jsonb   :trigger_config, default: {}
      t.jsonb   :conditions, default: []
      t.jsonb   :actions, default: []
      t.timestamps
    end

    add_index :automations, [:pipeline_id, :trigger_type]
    add_index :automations, [:workspace_id, :active]
  end
end
