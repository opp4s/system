class RemoveChatwootDependencies < ActiveRecord::Migration[7.1]
  def change
    drop_table :chatwoot_configs, if_exists: true

    if table_exists?(:whatsapp_instances) && column_exists?(:whatsapp_instances, :chatwoot_inbox_id)
      remove_column :whatsapp_instances, :chatwoot_inbox_id
    end

    if table_exists?(:conversations)
      change_column_null :conversations, :chatwoot_conversation_id, true if column_exists?(:conversations, :chatwoot_conversation_id)
      change_column_null :conversations, :chatwoot_account_id, true      if column_exists?(:conversations, :chatwoot_account_id)
    end
  end
end
