class CreateWorkspaces < ActiveRecord::Migration[7.1]
  def change
    create_table :workspaces do |t|
      t.string     :name,    null: false
      t.string     :slug,    null: false
      t.string     :plan,    null: false, default: "starter"
      t.references :owner,   null: false, foreign_key: { to_table: :users }
      t.jsonb      :settings, null: false, default: {}

      t.timestamps
    end

    add_index :workspaces, :slug, unique: true
    add_index :workspaces, :settings, using: :gin
  end
end
