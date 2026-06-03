class RemoveChatwootResiduals < ActiveRecord::Migration[7.1]
  def change
    remove_column :conversations, :chatwoot_conversation_id, :integer
    remove_column :conversations, :chatwoot_account_id, :string
    remove_column :conversations, :chatwoot_assignee_id, :integer
    remove_column :conversations, :inbox_id, :integer

    remove_column :contacts, :chatwoot_contact_id, :integer
    remove_column :contacts, :last_synced_at, :datetime
    remove_column :contacts, :chatwoot_created_at, :datetime

    remove_column :broadcast_messages, :chatwoot_message_id, :integer
  end
end
