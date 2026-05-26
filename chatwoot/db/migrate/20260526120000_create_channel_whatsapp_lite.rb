class CreateChannelWhatsappLite < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_whatsapp_lite do |t|
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_whatsapp_lite, :account_id
  end
end
