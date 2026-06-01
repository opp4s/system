class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :workspace,    null: false, foreign_key: true
      t.references :card,         null: true,  foreign_key: true
      t.references :contact,      null: true,  foreign_key: true
      t.references :conversation, null: true,  foreign_key: true

      t.string  :chatwoot_message_id, null: false
      t.text    :content,             null: false
      t.string  :message_type,        null: false, default: "incoming"  # incoming | outgoing
      t.string  :channel,             null: false, default: "whatsapp"  # whatsapp | telegram | etc
      t.string  :sender_name
      t.string  :sender_phone
      t.jsonb   :attachments,         default: []
      t.jsonb   :metadata,            default: {}
      t.datetime :embedded_at  # null = pendente para Qdrant; preenchido = já indexado

      t.timestamps
    end

    add_index :messages, [:workspace_id, :chatwoot_message_id], unique: true
    add_index :messages, :embedded_at
    add_index :messages, [:card_id, :created_at]
  end
end
