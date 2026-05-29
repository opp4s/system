class CreateAutomationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :automation_logs do |t|
      t.references :automation, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.string  :status, null: false
      t.jsonb   :actions_executed, default: []
      t.text    :error_message
      t.datetime :created_at, null: false
    end

    add_index :automation_logs, [:automation_id, :created_at]
    add_index :automation_logs, [:card_id, :created_at]
  end
end
