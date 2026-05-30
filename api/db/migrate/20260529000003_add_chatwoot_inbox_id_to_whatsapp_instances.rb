class AddChatwootInboxIdToWhatsappInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :whatsapp_instances, :chatwoot_inbox_id, :integer
    add_index  :whatsapp_instances, :chatwoot_inbox_id
  end
end
