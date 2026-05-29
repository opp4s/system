class CreateChatwootConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_configs do |t|
      t.references :workspace, null: false, foreign_key: true, index: { unique: true }
      t.string  :chatwoot_url,        null: false
      t.string  :chatwoot_account_id, null: false
      t.string  :chatwoot_api_token,  null: false   # armazenado criptografado
      t.string  :chatwoot_inbox_id
      t.jsonb   :settings, default: {}
      t.timestamps
    end
  end
end
