class CreateFunnelTables < ActiveRecord::Migration[7.0]
  def change
    create_table :funnels do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string     :name,        null: false
      t.string     :description
      t.string     :color,       default: '#1F93FF'
      t.integer    :position,    null: false, default: 0
      t.boolean    :is_default,  null: false, default: false
      t.timestamps
    end

    create_table :funnel_stages do |t|
      t.references :funnel, null: false, foreign_key: true, index: true
      t.string     :name,             null: false
      t.string     :color,            default: '#6C757D'
      t.integer    :position,         null: false, default: 0
      t.string     :stage_type,       null: false, default: 'intermediate'
      t.integer    :win_probability,  default: 0
      t.timestamps
    end

    create_table :funnel_cards do |t|
      t.references :funnel,         null: false, foreign_key: true, index: true
      t.references :funnel_stage,   null: false, foreign_key: true, index: true
      t.references :account,        null: false, foreign_key: true, index: true
      t.bigint     :assigned_agent_id
      t.bigint     :assigned_team_id
      t.string     :title,          null: false
      t.decimal    :value,          precision: 15, scale: 2, default: 0
      t.string     :currency,       default: 'BRL'
      t.text       :lost_reason
      t.datetime   :archived_at
      t.datetime   :stage_changed_at
      t.timestamps
    end

    add_index :funnel_cards, :assigned_agent_id
    add_index :funnel_cards, :assigned_team_id
    add_index :funnel_cards, :archived_at

    create_table :funnel_card_conversations do |t|
      t.references :funnel_card,   null: false, foreign_key: true, index: true
      t.references :conversation,  null: false, foreign_key: true, index: true
      t.boolean    :is_primary,    null: false, default: false
      t.timestamps
    end

    add_index :funnel_card_conversations, %i[funnel_card_id conversation_id], unique: true,
              name: 'idx_funnel_card_conversations_unique'

    create_table :funnel_card_events do |t|
      t.references :funnel_card, null: false, foreign_key: true, index: true
      t.references :account,     null: false, foreign_key: true, index: true
      t.bigint     :user_id
      t.string     :event_type,  null: false
      t.jsonb      :payload,     null: false, default: {}
      t.datetime   :created_at,  null: false
    end

    add_index :funnel_card_events, :user_id
    add_index :funnel_card_events, :event_type
    add_index :funnel_card_events, :created_at

    create_table :funnel_custom_field_values do |t|
      t.references :funnel_card,        null: false, foreign_key: true, index: true
      t.references :custom_attribute,   null: false, foreign_key: true, index: true
      t.text    :value_text
      t.decimal :value_numeric,  precision: 15, scale: 2
      t.boolean :value_boolean
      t.date    :value_date
      t.timestamps
    end

    add_index :funnel_custom_field_values, %i[funnel_card_id custom_attribute_id], unique: true,
              name: 'idx_funnel_custom_field_values_unique'
  end
end
