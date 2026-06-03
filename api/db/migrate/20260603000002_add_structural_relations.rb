class AddStructuralRelations < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversations, :whatsapp_instance, foreign_key: true, null: true
    add_reference :cards, :contact, foreign_key: true, null: true
  end
end
