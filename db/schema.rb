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

ActiveRecord::Schema.define(version: 20171104194511) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.integer "technology_id"
    t.boolean "is_private", default: false, null: false
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
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.boolean "attended"
    t.boolean "leader", default: false
    t.integer "guests_registered", default: 0
    t.integer "guests_attended", default: 0
    t.string "accomodations", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.boolean "is_archived", default: false
    t.date "signed_waiver_on"
    t.integer "primary_location_id"
    t.string "fname"
    t.string "lname"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "events", "locations"
  add_foreign_key "events", "technologies"
  add_foreign_key "registrations", "events"
  add_foreign_key "registrations", "users"
end
