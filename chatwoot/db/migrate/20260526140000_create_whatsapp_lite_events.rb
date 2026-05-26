class CreateWhatsappLiteEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_lite_events do |t|
      t.references :account, null: false, foreign_key: true
      t.string  :instance_id, null: false
      t.string  :event_type,  null: false  # webhook_received, message_sent, message_failed, connection_changed, message_edited
      t.string  :source_id                 # evolution key.id (quando aplicável)
      t.string  :status                    # resultado: success, failed, skipped, duplicate
      t.jsonb   :metadata, default: {}     # dados extras (error message, phone, from_me, etc.)
      t.timestamps
    end

    add_index :whatsapp_lite_events, [:account_id, :created_at]
    add_index :whatsapp_lite_events, [:instance_id, :event_type]
    add_index :whatsapp_lite_events, :source_id
  end
end
