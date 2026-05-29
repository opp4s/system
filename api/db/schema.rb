# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_05_27_200004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "card_events", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.bigint "workspace_id", null: false
    t.bigint "user_id"
    t.string "event_type", null: false
    t.jsonb "payload", default: {}
    t.datetime "created_at", null: false
    t.index ["card_id", "created_at"], name: "index_card_events_on_card_id_and_created_at"
    t.index ["card_id"], name: "index_card_events_on_card_id"
    t.index ["event_type"], name: "index_card_events_on_event_type"
    t.index ["workspace_id"], name: "index_card_events_on_workspace_id"
  end

  create_table "cards", force: :cascade do |t|
    t.bigint "pipeline_id", null: false
    t.bigint "stage_id", null: false
    t.bigint "workspace_id", null: false
    t.bigint "assigned_agent_id"
    t.bigint "assigned_team_id"
    t.string "title", null: false
    t.decimal "value", precision: 15, scale: 2, default: "0.0"
    t.string "currency", default: "BRL"
    t.text "lost_reason"
    t.string "contact_name"
    t.string "contact_phone"
    t.string "contact_email"
    t.jsonb "custom_fields", default: {}
    t.datetime "stage_changed_at"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_cards_on_archived_at"
    t.index ["assigned_agent_id"], name: "index_cards_on_assigned_agent_id"
    t.index ["custom_fields"], name: "index_cards_on_custom_fields", using: :gin
    t.index ["pipeline_id"], name: "index_cards_on_pipeline_id"
    t.index ["stage_id", "archived_at"], name: "idx_cards_stage_active"
    t.index ["stage_id"], name: "index_cards_on_stage_id"
    t.index ["workspace_id"], name: "index_cards_on_workspace_id"
  end

  create_table "pipelines", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.string "name", null: false
    t.string "description"
    t.string "color", default: "#6366F1"
    t.integer "position", default: 0, null: false
    t.boolean "is_default", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workspace_id", "position"], name: "index_pipelines_on_workspace_id_and_position"
    t.index ["workspace_id"], name: "index_pipelines_on_workspace_id"
  end

  create_table "stages", force: :cascade do |t|
    t.bigint "pipeline_id", null: false
    t.string "name", null: false
    t.string "color", default: "#6C757D"
    t.integer "position", default: 0, null: false
    t.string "stage_type", default: "intermediate", null: false
    t.integer "win_probability", default: 0
    t.jsonb "loss_reasons", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pipeline_id", "position"], name: "index_stages_on_pipeline_id_and_position"
    t.index ["pipeline_id"], name: "index_stages_on_pipeline_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", default: "", null: false
    t.string "avatar_url"
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspace_memberships", force: :cascade do |t|
    t.bigint "workspace_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "agent", null: false
    t.datetime "accepted_at"
    t.datetime "invited_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_workspace_memberships_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_workspace_memberships_on_workspace_id_and_user_id", unique: true
    t.index ["workspace_id"], name: "index_workspace_memberships_on_workspace_id"
  end

  create_table "workspaces", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "plan", default: "starter", null: false
    t.bigint "owner_id", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_workspaces_on_owner_id"
    t.index ["settings"], name: "index_workspaces_on_settings", using: :gin
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "card_events", "cards"
  add_foreign_key "card_events", "workspaces"
  add_foreign_key "cards", "pipelines"
  add_foreign_key "cards", "stages"
  add_foreign_key "cards", "workspaces"
  add_foreign_key "pipelines", "workspaces"
  add_foreign_key "stages", "pipelines"
  add_foreign_key "workspace_memberships", "users"
  add_foreign_key "workspace_memberships", "workspaces"
  add_foreign_key "workspaces", "users", column: "owner_id"
end
