class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.references :workspace,           null: false, foreign_key: true, index: true
      t.integer    :chatwoot_contact_id, null: false
      t.string     :name,                null: false, default: ""
      t.string     :email
      t.string     :phone_number
      t.string     :avatar_url
      t.jsonb      :additional_attributes, default: {}
      t.jsonb      :custom_attributes,     default: {}
      t.datetime   :last_synced_at
      t.datetime   :chatwoot_created_at

      t.timestamps
    end

    add_index :contacts, [:workspace_id, :chatwoot_contact_id],
              unique: true, name: "idx_contacts_workspace_cw_id"
    add_index :contacts, :phone_number
    add_index :contacts, :email
  end
end
