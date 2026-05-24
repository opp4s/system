class CreateWhatsappLiteChannels < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_lite_channels do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox,   null: false, foreign_key: true
      t.string  :instance_id,  null: false
      t.string  :phone_number, null: false
      t.integer :status,       null: false, default: 0
      t.datetime :qr_expires_at
      t.timestamps
    end

    add_index :whatsapp_lite_channels, :instance_id, unique: true
    add_index :whatsapp_lite_channels, [:account_id, :phone_number]
  end
end
