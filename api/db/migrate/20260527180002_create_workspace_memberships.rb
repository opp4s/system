class CreateWorkspaceMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :workspace_memberships do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user,      null: false, foreign_key: true
      t.string     :role,      null: false, default: "agent"
      t.datetime   :accepted_at
      t.datetime   :invited_at

      t.timestamps
    end

    add_index :workspace_memberships, [:workspace_id, :user_id], unique: true
  end
end
