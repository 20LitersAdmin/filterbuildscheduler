# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171123015203) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "components", force: :cascade do |t|
    t.string "name", null: false
    t.integer "sample_size"
    t.float "sample_weight"
    t.string "common_id"
    t.boolean "completed_tech", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.float "tare_weight", default: 0.0
    t.index ["deleted_at"], name: "index_components_on_deleted_at"
  end

  create_table "components_parts", id: false, force: :cascade do |t|
    t.bigint "component_id", null: false
    t.bigint "part_id", null: false
    t.integer "parts_per_component", default: 1, null: false
    t.index ["component_id", "part_id"], name: "index_components_parts_on_component_id_and_part_id"
    t.index ["part_id", "component_id"], name: "index_components_parts_on_part_id_and_component_id"
  end

  create_table "components_technologies", id: false, force: :cascade do |t|
    t.bigint "component_id", null: false
    t.bigint "technology_id", null: false
    t.integer "components_per_technology", default: 1, null: false
    t.index ["component_id", "technology_id"], name: "index_components_technologies_on_component_id_and_technology_id"
    t.index ["technology_id", "component_id"], name: "index_components_technologies_on_technology_id_and_component_id"
  end

  create_table "counts", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "inventory_id", null: false
    t.bigint "component_id"
    t.bigint "part_id"
    t.bigint "material_id"
    t.integer "loose_count", default: 0, null: false
    t.integer "unopened_boxes_count", default: 0, null: false
    t.datetime "deleted_at"
    t.index ["component_id"], name: "index_counts_on_component_id"
    t.index ["deleted_at"], name: "index_counts_on_deleted_at"
    t.index ["inventory_id"], name: "index_counts_on_inventory_id"
    t.index ["material_id"], name: "index_counts_on_material_id"
    t.index ["part_id"], name: "index_counts_on_part_id"
    t.index ["user_id"], name: "index_counts_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cron"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "title", null: false
    t.string "description"
    t.integer "min_registrations"
    t.integer "max_registrations"
    t.integer "min_leaders"
    t.integer "max_leaders"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "location_id", null: false
    t.integer "technology_id", null: false
    t.boolean "is_private", default: false, null: false
    t.integer "item_goal"
    t.integer "technologies_built"
    t.datetime "deleted_at"
    t.integer "attendance"
    t.integer "boxes_packed"
    t.index ["deleted_at"], name: "index_events_on_deleted_at"
  end

  create_table "inventories", force: :cascade do |t|
    t.boolean "receiving", default: false, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_id"
    t.boolean "shipping", default: false, null: false
    t.boolean "manual", default: false, null: false
    t.date "date", default: "2017-11-22", null: false
    t.index ["deleted_at"], name: "index_inventories_on_deleted_at"
    t.index ["event_id"], name: "index_inventories_on_event_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "map_url"
    t.string "photo_url"
    t.string "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_locations_on_deleted_at"
  end

  create_table "materials", force: :cascade do |t|
    t.string "name", null: false
    t.string "supplier"
    t.string "order_url"
    t.integer "min_order"
    t.string "order_id"
    t.float "weeks_to_deliver"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.integer "additional_cost_cents", default: 0, null: false
    t.string "additional_cost_currency", default: "USD", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.index ["deleted_at"], name: "index_materials_on_deleted_at"
  end

  create_table "materials_parts", id: false, force: :cascade do |t|
    t.bigint "material_id", null: false
    t.bigint "part_id", null: false
    t.integer "parts_per_material", null: false
    t.index ["material_id", "part_id"], name: "index_materials_parts_on_material_id_and_part_id"
    t.index ["part_id", "material_id"], name: "index_materials_parts_on_part_id_and_material_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "name", null: false
    t.string "supplier"
    t.string "order_url"
    t.integer "min_order"
    t.string "order_id"
    t.string "common_id"
    t.float "weeks_to_deliver"
    t.integer "sample_size"
    t.float "sample_weight"
    t.boolean "made_from_materials", default: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.integer "additional_cost_cents", default: 0, null: false
    t.string "additional_cost_currency", default: "USD", null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.index ["deleted_at"], name: "index_parts_on_deleted_at"
  end

  create_table "parts_technologies", id: false, force: :cascade do |t|
    t.bigint "part_id", null: false
    t.bigint "technology_id", null: false
    t.integer "parts_per_technology", default: 1, null: false
    t.index ["part_id", "technology_id"], name: "index_parts_technologies_on_part_id_and_technology_id"
    t.index ["technology_id", "part_id"], name: "index_parts_technologies_on_technology_id_and_part_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.boolean "attended"
    t.boolean "leader", default: false
    t.integer "guests_registered", default: 0
    t.integer "guests_attended", default: 0
    t.string "accommodations", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_registrations_on_deleted_at"
    t.index ["user_id", "event_id"], name: "index_registrations_on_user_id_and_event_id", unique: true
  end

  create_table "technologies", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.integer "ideal_build_length"
    t.integer "ideal_group_size"
    t.integer "ideal_leaders"
    t.boolean "family_friendly"
    t.float "unit_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "img_url"
    t.string "info_url"
    t.string "owner"
    t.index ["deleted_at"], name: "index_technologies_on_deleted_at"
  end

  create_table "technologies_users", id: false, force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "technology_id", null: false
    t.index ["technology_id", "user_id"], name: "index_technologies_users_on_technology_id_and_user_id"
    t.index ["user_id", "technology_id"], name: "index_technologies_users_on_user_id_and_technology_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.boolean "is_leader"
    t.boolean "is_admin"
    t.date "signed_waiver_on"
    t.integer "primary_location_id"
    t.string "fname"
    t.string "lname"
    t.datetime "deleted_at"
    t.string "authentication_token", limit: 30
    t.boolean "does_inventory"
    t.boolean "send_notification_emails", default: false
    t.boolean "send_inventory_emails", default: false
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "events", "locations"
  add_foreign_key "events", "technologies"
  add_foreign_key "registrations", "events"
  add_foreign_key "registrations", "users"
end
