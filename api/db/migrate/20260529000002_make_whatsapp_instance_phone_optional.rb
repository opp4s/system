class MakeWhatsappInstancePhoneOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :whatsapp_instances, :phone_number, true
  end
end
