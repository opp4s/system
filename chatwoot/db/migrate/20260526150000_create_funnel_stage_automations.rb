class CreateFunnelStageAutomations < ActiveRecord::Migration[7.0]
  def change
    create_table :funnel_stage_automations do |t|
      t.references :funnel_stage, null: false, foreign_key: true, index: true
      t.references :account,      null: false, foreign_key: true, index: true
      t.string  :automation_type, null: false   # webhook | message | task
      t.string  :trigger_event,   null: false, default: 'on_enter'  # on_enter | on_leave
      t.jsonb   :config,          null: false, default: {}
      t.boolean :active,          null: false, default: true
      t.integer :position,        null: false, default: 0
      t.timestamps
    end

    add_index :funnel_stage_automations, %i[funnel_stage_id active]
  end
end
