class CreateBroadcastMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcast_messages do |t|
      t.references :broadcast, null: false, foreign_key: true
      t.references :contact,   null: false, foreign_key: true
      t.string  :status,              null: false, default: "pending"
      t.string  :error_message
      t.bigint  :chatwoot_message_id
      t.datetime :sent_at
      t.datetime :created_at,         null: false
    end

    add_index :broadcast_messages, [:broadcast_id, :status]
    add_index :broadcast_messages, [:contact_id, :broadcast_id], unique: true
  end
end
