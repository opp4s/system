class CreatePipelines < ActiveRecord::Migration[7.1]
  def change
    create_table :pipelines do |t|
      t.references :workspace,   null: false, foreign_key: true
      t.string     :name,        null: false
      t.string     :description
      t.string     :color,       default: "#6366F1"
      t.integer    :position,    null: false, default: 0
      t.boolean    :is_default,  default: false

      t.timestamps
    end

    add_index :pipelines, [:workspace_id, :position]
  end
end
