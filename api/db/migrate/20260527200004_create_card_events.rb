class CreateCardEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :card_events do |t|
      t.references :card,       null: false, foreign_key: true
      t.references :workspace,  null: false, foreign_key: true
      t.bigint     :user_id
      t.string     :event_type, null: false
      t.jsonb      :payload,    default: {}

      t.datetime   :created_at, null: false
    end

    add_index :card_events, :event_type
    add_index :card_events, [:card_id, :created_at]
  end
end
