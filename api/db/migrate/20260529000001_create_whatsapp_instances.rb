class CreateWhatsappInstances < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_instances do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :instance_id,  null: false
      t.string :phone_number, null: false
      t.string :status,       null: false, default: "disconnected"
      t.timestamps
    end
    add_index :whatsapp_instances, [:workspace_id, :instance_id], unique: true
  end
end
