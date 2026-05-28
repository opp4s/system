class CreateBroadcasts < ActiveRecord::Migration[7.1]
  def change
    create_table :broadcasts do |t|
      t.references :workspace,   null: false, foreign_key: true
      t.references :pipeline,    foreign_key: true
      t.bigint     :created_by_id
      t.string  :name,               null: false
      t.text    :message,            null: false
      t.string  :media_url
      t.string  :media_type
      t.string  :status,             null: false, default: "draft"
      t.jsonb   :audience_filters,   default: {}, null: false
      t.integer :total_recipients,   default: 0,  null: false
      t.integer :sent_count,         default: 0,  null: false
      t.integer :failed_count,       default: 0,  null: false
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :broadcasts, [:workspace_id, :status]
    add_index :broadcasts, :scheduled_at
    add_index :broadcasts, :created_by_id
  end
end
