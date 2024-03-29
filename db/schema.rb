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

ActiveRecord::Schema.define(version: 2023_02_18_192947) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assemblies", force: :cascade do |t|
    t.bigint "combination_id", null: false
    t.string "combination_type", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "depth"
    t.boolean "affects_price_only", default: false, null: false
    t.index ["combination_id", "combination_type"], name: "index_assemblies_on_combination_id_and_combination_type"
    t.index ["item_id", "item_type"], name: "index_assemblies_on_item_id_and_item_type"
  end

  create_table "components", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.text "comments"
    t.boolean "only_loose", default: false
    t.text "description"
    t.string "uid"
    t.integer "loose_count", default: 0
    t.integer "box_count", default: 0
    t.integer "available_count", default: 0
    t.jsonb "history", default: {}, null: false
    t.jsonb "quantities", default: {}, null: false
    t.integer "can_be_produced", default: 0
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.boolean "below_minimum", default: false, null: false
    t.integer "minimum_on_hand", default: 0, null: false
    t.integer "goal_remainder", default: 0
    t.string "box_type", default: "box"
    t.text "box_notes"
    t.jsonb "allocations", default: {}, null: false
    t.index ["discarded_at"], name: "index_components_on_discarded_at"
  end

  create_table "constituent_emails", force: :cascade do |t|
    t.string "value", null: false
    t.integer "constituent_id"
    t.boolean "is_primary", default: false, null: false
    t.string "email_type"
  end

  create_table "constituent_phones", force: :cascade do |t|
    t.string "value", null: false
    t.integer "constituent_id"
    t.boolean "is_primary", default: false, null: false
    t.string "phone_type"
  end

  create_table "constituents", force: :cascade do |t|
    t.string "name", null: false
    t.string "primary_email"
    t.string "primary_phone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "counts", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "inventory_id", null: false
    t.integer "loose_count", default: 0, null: false
    t.integer "unopened_boxes_count", default: 0, null: false
    t.boolean "partial_box", default: false
    t.boolean "partial_loose", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "item_type"
    t.bigint "item_id"
    t.index ["inventory_id"], name: "index_counts_on_inventory_id"
    t.index ["item_type", "item_id"], name: "index_counts_on_item"
    t.index ["user_id"], name: "index_counts_on_user_id"
  end

  create_table "emails", force: :cascade do |t|
    t.bigint "oauth_user_id", null: false
    t.string "from", array: true
    t.string "to", array: true
    t.string "subject"
    t.datetime "datetime"
    t.text "body"
    t.text "snippet"
    t.string "gmail_id"
    t.string "message_id"
    t.datetime "sent_to_crm_on"
    t.string "matched_constituents", array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "crm_job_id", array: true
    t.string "direction"
    t.string "channel", default: "Email"
    t.index ["gmail_id"], name: "index_emails_on_gmail_id"
    t.index ["message_id"], name: "index_emails_on_message_id"
    t.index ["oauth_user_id"], name: "index_emails_on_oauth_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "min_registrations"
    t.integer "max_registrations"
    t.integer "min_leaders"
    t.integer "max_leaders"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "location_id"
    t.integer "technology_id"
    t.boolean "is_private", default: false, null: false
    t.integer "item_goal", default: 0, null: false
    t.integer "technologies_built", default: 0, null: false
    t.datetime "discarded_at"
    t.integer "attendance", default: 0
    t.integer "boxes_packed", default: 0, null: false
    t.string "contact_name"
    t.string "contact_email"
    t.boolean "emails_sent", default: false
    t.datetime "reminder_sent_at"
    t.integer "impact_results", default: 0, null: false
    t.boolean "allow_guests", default: true, null: false
    t.index ["discarded_at"], name: "index_events_on_discarded_at"
  end

  create_table "inventories", force: :cascade do |t|
    t.boolean "receiving", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "event_id"
    t.boolean "shipping", default: false, null: false
    t.boolean "manual", default: false, null: false
    t.date "date", null: false
    t.datetime "completed_at"
    t.datetime "report_sent_at"
    t.jsonb "history", default: {}, null: false
    t.string "technologies", default: [], array: true
    t.boolean "extrapolate", default: false, null: false
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
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.index ["discarded_at"], name: "index_locations_on_discarded_at"
  end

  create_table "materials", force: :cascade do |t|
    t.string "name", null: false
    t.string "order_url"
    t.integer "min_order", default: 1
    t.string "sku"
    t.float "weeks_to_deliver", default: 1.0
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "minimum_on_hand", default: 0, null: false
    t.text "comments"
    t.bigint "supplier_id"
    t.boolean "only_loose", default: false
    t.text "description"
    t.datetime "last_ordered_at"
    t.integer "last_ordered_quantity"
    t.datetime "last_received_at"
    t.integer "last_received_quantity"
    t.string "uid"
    t.integer "loose_count", default: 0
    t.integer "box_count", default: 0
    t.integer "available_count", default: 0
    t.jsonb "history", default: {}, null: false
    t.jsonb "quantities", default: {}, null: false
    t.boolean "below_minimum", default: false, null: false
    t.integer "goal_remainder", default: 0
    t.string "box_type", default: "box"
    t.text "box_notes"
    t.jsonb "allocations", default: {}, null: false
    t.index ["discarded_at"], name: "index_materials_on_discarded_at"
    t.index ["supplier_id"], name: "index_materials_on_supplier_id"
  end

  create_table "oauth_users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "oauth_id"
    t.string "oauth_provider"
    t.string "oauth_token"
    t.string "oauth_refresh_token"
    t.datetime "oauth_expires_at"
    t.boolean "sync_emails"
    t.datetime "last_email_sync"
    t.string "manual_query"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "oauth_error_message"
    t.index ["email"], name: "index_oauth_users_on_email", unique: true
    t.index ["oauth_id"], name: "index_oauth_users_on_oauth_id", unique: true
    t.index ["oauth_token"], name: "index_oauth_users_on_oauth_token", unique: true
  end

  create_table "parts", force: :cascade do |t|
    t.string "name", null: false
    t.string "order_url"
    t.integer "min_order", default: 1
    t.string "sku"
    t.float "weeks_to_deliver", default: 1.0
    t.boolean "made_from_material", default: false
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quantity_per_box", default: 1
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "minimum_on_hand", default: 0, null: false
    t.text "comments"
    t.bigint "supplier_id"
    t.boolean "only_loose", default: false
    t.text "description"
    t.datetime "last_ordered_at"
    t.integer "last_ordered_quantity"
    t.datetime "last_received_at"
    t.integer "last_received_quantity"
    t.string "uid"
    t.integer "loose_count", default: 0
    t.integer "box_count", default: 0
    t.integer "available_count", default: 0
    t.jsonb "history", default: {}, null: false
    t.jsonb "quantities", default: {}, null: false
    t.integer "can_be_produced", default: 0
    t.bigint "material_id"
    t.integer "quantity_from_material", default: 0, null: false
    t.boolean "below_minimum", default: false, null: false
    t.integer "goal_remainder", default: 0
    t.string "box_type", default: "box"
    t.text "box_notes"
    t.jsonb "allocations", default: {}, null: false
    t.index ["discarded_at"], name: "index_parts_on_discarded_at"
    t.index ["material_id"], name: "index_parts_on_material_id"
    t.index ["supplier_id"], name: "index_parts_on_supplier_id"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.boolean "attended"
    t.boolean "leader", default: false
    t.integer "guests_registered", default: 0
    t.integer "guests_attended", default: 0
    t.text "accommodations", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.datetime "reminder_sent_at"
    t.index ["discarded_at"], name: "index_registrations_on_discarded_at"
    t.index ["user_id", "event_id"], name: "index_registrations_on_user_id_and_event_id", unique: true
  end

  create_table "setups", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "creator_id", null: false
    t.datetime "date"
    t.datetime "reminder_sent_at"
    t.string "reminder_sent_to", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_setups_on_creator_id"
    t.index ["event_id"], name: "index_setups_on_event_id"
  end

  create_table "setups_users", id: false, force: :cascade do |t|
    t.bigint "setup_id", null: false
    t.bigint "user_id", null: false
    t.index ["setup_id", "user_id"], name: "index_setups_users_on_setup_id_and_user_id", unique: true
    t.index ["user_id", "setup_id"], name: "index_setups_users_on_user_id_and_setup_id", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "url"
    t.string "email"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "province"
    t.string "country"
    t.string "phone"
    t.string "poc_name"
    t.string "poc_email"
    t.string "poc_phone"
    t.string "poc_address"
    t.text "comments"
    t.datetime "discarded_at"
    t.index ["name"], name: "index_suppliers_on_name"
  end

  create_table "technologies", force: :cascade do |t|
    t.string "name", null: false
    t.text "public_description"
    t.integer "ideal_build_length"
    t.integer "ideal_group_size"
    t.integer "ideal_leaders"
    t.boolean "family_friendly"
    t.float "unit_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "discarded_at"
    t.string "info_url"
    t.string "owner"
    t.integer "people", default: 0, null: false
    t.integer "lifespan_in_years", default: 0, null: false
    t.integer "liters_per_day", default: 0
    t.text "comments"
    t.integer "monthly_production_rate", default: 1, null: false
    t.string "short_name"
    t.string "uid"
    t.boolean "only_loose", default: false
    t.integer "loose_count", default: 0
    t.integer "box_count", default: 0
    t.integer "available_count", default: 0
    t.jsonb "history", default: {}, null: false
    t.jsonb "quantities", default: {}, null: false
    t.integer "quantity_per_box", default: 1
    t.integer "can_be_produced", default: 0
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.boolean "below_minimum", default: false, null: false
    t.integer "minimum_on_hand", default: 0, null: false
    t.text "description"
    t.integer "default_goal", default: 0, null: false
    t.integer "goal_remainder", default: 0
    t.string "box_type", default: "box"
    t.text "box_notes"
    t.boolean "for_events", default: true, null: false
    t.boolean "for_inventories", default: true, null: false
    t.index ["discarded_at"], name: "index_technologies_on_discarded_at"
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
    t.boolean "is_leader", default: false
    t.boolean "is_admin", default: false
    t.date "signed_waiver_on"
    t.integer "primary_location_id"
    t.string "fname"
    t.string "lname"
    t.datetime "discarded_at"
    t.string "authentication_token", limit: 30
    t.boolean "does_inventory", default: false
    t.boolean "send_event_emails", default: false
    t.boolean "send_inventory_emails", default: false
    t.boolean "email_opt_out", default: false
    t.boolean "available_business_hours", default: false, null: false
    t.boolean "available_after_hours", default: false, null: false
    t.integer "leader_type"
    t.string "leader_notes"
    t.boolean "is_scheduler", default: false
    t.boolean "is_data_manager", default: false
    t.boolean "is_oauth_admin", default: false
    t.boolean "is_setup_crew", default: false, null: false
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "emails", "oauth_users"
  add_foreign_key "events", "locations"
  add_foreign_key "events", "technologies"
  add_foreign_key "registrations", "events"
  add_foreign_key "registrations", "users"
  add_foreign_key "setups", "events"
  add_foreign_key "setups", "users", column: "creator_id"
end
