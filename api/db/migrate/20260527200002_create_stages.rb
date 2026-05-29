class CreateStages < ActiveRecord::Migration[7.1]
  def change
    create_table :stages do |t|
      t.references :pipeline,       null: false, foreign_key: true
      t.string     :name,           null: false
      t.string     :color,          default: "#6C757D"
      t.integer    :position,       null: false, default: 0
      t.string     :stage_type,     null: false, default: "intermediate"
      t.integer    :win_probability, default: 0
      t.jsonb      :loss_reasons,   default: []

      t.timestamps
    end

    add_index :stages, [:pipeline_id, :position]
  end
end
