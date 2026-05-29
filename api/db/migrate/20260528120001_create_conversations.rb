class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :workspace, null: false, foreign_key: true, index: true
      t.references :card,      null: true,  foreign_key: true, index: true

      t.integer :chatwoot_conversation_id, null: false
      t.string  :chatwoot_account_id,      null: false
      t.integer :inbox_id
      t.integer :contact_id
      t.string  :status,                   null: false, default: "open"
      t.integer :chatwoot_assignee_id
      t.datetime :last_activity_at
      t.jsonb   :meta,                     default: {}

      t.timestamps
    end

    add_index :conversations, [:workspace_id, :chatwoot_conversation_id],
              unique: true, name: "idx_conversations_workspace_cw_id"
    add_index :conversations, :status
  end
end
