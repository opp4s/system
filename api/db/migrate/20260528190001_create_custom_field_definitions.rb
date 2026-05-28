class CreateCustomFieldDefinitions < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_field_definitions do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :pipeline,  null: true,  foreign_key: true
      t.string  :name,       null: false
      t.string  :field_type, null: false
      t.jsonb   :options,    default: {}
      t.integer :position,   default: 0
      t.string  :tab_name,   default: "Principal"
      t.boolean :required,   default: false

      t.timestamps
    end

    add_index :custom_field_definitions, [:workspace_id, :pipeline_id]
    add_index :custom_field_definitions, :field_type
  end
end
