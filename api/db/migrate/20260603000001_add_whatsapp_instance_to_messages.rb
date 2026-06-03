class AddWhatsappInstanceToMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :messages, :whatsapp_instance, null: true, foreign_key: true
  end
end
