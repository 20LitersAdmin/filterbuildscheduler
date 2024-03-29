# frozen_string_literal: true

class InitSchema < ActiveRecord::Migration[5.1]
  def up
    # These are extensions that must be enabled in order to support this database
    enable_extension 'plpgsql'

    create_table 'components', force: :cascade do |t|
      t.string 'name', null: false
      t.integer 'sample_size'
      t.float 'sample_weight'
      t.string 'common_id'
      t.boolean 'completed_tech', default: false
      t.datetime 'deleted_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'quantity_per_box', default: 1
      t.float 'tare_weight', default: 0.0
      t.text 'comments'
      t.boolean 'only_loose', default: false
      t.index ['deleted_at'], name: 'index_components_on_deleted_at'
    end

    create_table 'counts', force: :cascade do |t|
      t.bigint 'user_id'
      t.bigint 'inventory_id', null: false
      t.bigint 'component_id'
      t.bigint 'part_id'
      t.bigint 'material_id'
      t.integer 'loose_count', default: 0, null: false
      t.integer 'unopened_boxes_count', default: 0, null: false
      t.datetime 'deleted_at'
      t.integer 'extrapolated_count', default: 0, null: false
      t.boolean 'partial_box', default: false
      t.boolean 'partial_loose', default: false
      t.index ['component_id'], name: 'index_counts_on_component_id'
      t.index ['deleted_at'], name: 'index_counts_on_deleted_at'
      t.index ['inventory_id'], name: 'index_counts_on_inventory_id'
      t.index ['material_id'], name: 'index_counts_on_material_id'
      t.index ['part_id'], name: 'index_counts_on_part_id'
      t.index ['user_id'], name: 'index_counts_on_user_id'
    end

    create_table 'delayed_jobs', force: :cascade do |t|
      t.integer 'priority', default: 0, null: false
      t.integer 'attempts', default: 0, null: false
      t.text 'handler', null: false
      t.text 'last_error'
      t.datetime 'run_at'
      t.datetime 'locked_at'
      t.datetime 'failed_at'
      t.string 'locked_by'
      t.string 'queue'
      t.datetime 'created_at'
      t.datetime 'updated_at'
      t.string 'cron'
      t.index %w[priority run_at], name: 'delayed_jobs_priority'
    end

    create_table 'events', force: :cascade do |t|
      t.datetime 'start_time', null: false
      t.datetime 'end_time', null: false
      t.string 'title', null: false
      t.string 'description'
      t.integer 'min_registrations'
      t.integer 'max_registrations'
      t.integer 'min_leaders'
      t.integer 'max_leaders'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'location_id', null: false
      t.integer 'technology_id', null: false
      t.boolean 'is_private', default: false, null: false
      t.integer 'item_goal', default: 0, null: false
      t.integer 'technologies_built', default: 0, null: false
      t.datetime 'deleted_at'
      t.integer 'attendance', default: 0
      t.integer 'boxes_packed', default: 0, null: false
      t.string 'contact_name'
      t.string 'contact_email'
      t.boolean 'emails_sent', default: false
      t.index ['deleted_at'], name: 'index_events_on_deleted_at'
    end

    create_table 'extrapolate_component_parts', force: :cascade do |t|
      t.bigint 'component_id', null: false
      t.bigint 'part_id', null: false
      t.integer 'parts_per_component', default: 1, null: false
      t.index %w[component_id part_id], name: 'by_component_and_part', unique: true
      t.index %w[part_id component_id], name: 'by_part_and_component', unique: true
    end

    create_table 'extrapolate_material_parts', force: :cascade do |t|
      t.bigint 'material_id', null: false
      t.bigint 'part_id', null: false
      t.integer 'parts_per_material', default: 1, null: false
      t.index %w[material_id part_id], name: 'by_material_and_part', unique: true
      t.index %w[part_id material_id], name: 'by_part_and_material', unique: true
    end

    create_table 'extrapolate_technology_components', force: :cascade do |t|
      t.bigint 'component_id', null: false
      t.bigint 'technology_id', null: false
      t.integer 'components_per_technology', default: 1, null: false
      t.boolean 'required', default: false
      t.index %w[component_id technology_id], name: 'by_component_and_technology', unique: true
      t.index %w[technology_id component_id], name: 'by_technology_and_component', unique: true
    end

    create_table 'extrapolate_technology_materials', force: :cascade do |t|
      t.bigint 'technology_id'
      t.bigint 'material_id'
      t.float 'materials_per_technology', default: 1.0, null: false
      t.boolean 'required', default: false, null: false
      t.index %w[material_id technology_id], name: 'index_materials_technologies_on_material'
      t.index ['material_id'], name: 'index_extrapolate_technology_materials_on_material_id'
      t.index %w[technology_id material_id], name: 'index_materials_technologies_on_technology'
      t.index ['technology_id'], name: 'index_extrapolate_technology_materials_on_technology_id'
    end

    create_table 'extrapolate_technology_parts', force: :cascade do |t|
      t.bigint 'part_id', null: false
      t.bigint 'technology_id', null: false
      t.integer 'parts_per_technology', default: 1, null: false
      t.boolean 'required', default: false
      t.index %w[part_id technology_id], name: 'by_part_and_technology', unique: true
      t.index %w[technology_id part_id], name: 'by_technology_and_part', unique: true
    end

    create_table 'inventories', force: :cascade do |t|
      t.boolean 'receiving', default: false, null: false
      t.datetime 'deleted_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.bigint 'event_id'
      t.boolean 'shipping', default: false, null: false
      t.boolean 'manual', default: false, null: false
      t.date 'date', null: false
      t.datetime 'completed_at'
      t.index ['deleted_at'], name: 'index_inventories_on_deleted_at'
      t.index ['event_id'], name: 'index_inventories_on_event_id'
    end

    create_table 'locations', force: :cascade do |t|
      t.string 'name', null: false
      t.string 'address1'
      t.string 'address2'
      t.string 'city'
      t.string 'state'
      t.string 'zip'
      t.string 'map_url'
      t.string 'photo_url'
      t.string 'instructions'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.datetime 'deleted_at'
      t.index ['deleted_at'], name: 'index_locations_on_deleted_at'
    end

    create_table 'materials', force: :cascade do |t|
      t.string 'name', null: false
      t.string 'order_url'
      t.integer 'min_order', default: 1
      t.string 'sku'
      t.float 'weeks_to_deliver', default: 1.0
      t.datetime 'deleted_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'quantity_per_box', default: 1
      t.integer 'additional_cost_cents', default: 0, null: false
      t.string 'additional_cost_currency', default: 'USD', null: false
      t.integer 'price_cents', default: 0, null: false
      t.string 'price_currency', default: 'USD', null: false
      t.integer 'minimum_on_hand', default: 0, null: false
      t.text 'comments'
      t.bigint 'supplier_id'
      t.integer 'shipping_cost_cents', default: 0, null: false
      t.string 'shipping_cost_currency', default: 'USD', null: false
      t.integer 'wire_transfer_cost_cents', default: 0, null: false
      t.string 'wire_transfer_cost_currency', default: 'USD', null: false
      t.boolean 'only_loose', default: false
      t.index ['deleted_at'], name: 'index_materials_on_deleted_at'
      t.index ['supplier_id'], name: 'index_materials_on_supplier_id'
    end

    create_table 'parts', force: :cascade do |t|
      t.string 'name', null: false
      t.string 'order_url'
      t.integer 'min_order', default: 1
      t.string 'sku'
      t.float 'weeks_to_deliver', default: 1.0
      t.integer 'sample_size'
      t.float 'sample_weight'
      t.boolean 'made_from_materials', default: false
      t.datetime 'deleted_at'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'quantity_per_box', default: 1
      t.integer 'additional_cost_cents', default: 0, null: false
      t.string 'additional_cost_currency', default: 'USD', null: false
      t.integer 'price_cents', default: 0, null: false
      t.string 'price_currency', default: 'USD', null: false
      t.integer 'minimum_on_hand', default: 0, null: false
      t.integer 'shipping_cost_cents', default: 0, null: false
      t.string 'shipping_cost_currency', default: 'USD', null: false
      t.integer 'wire_transfer_cost_cents', default: 0, null: false
      t.string 'wire_transfer_cost_currency', default: 'USD', null: false
      t.text 'comments'
      t.bigint 'supplier_id'
      t.boolean 'only_loose', default: false
      t.index ['deleted_at'], name: 'index_parts_on_deleted_at'
      t.index ['supplier_id'], name: 'index_parts_on_supplier_id'
    end

    create_table 'registrations', force: :cascade do |t|
      t.integer 'user_id', null: false
      t.integer 'event_id', null: false
      t.boolean 'attended'
      t.boolean 'leader', default: false
      t.integer 'guests_registered', default: 0
      t.integer 'guests_attended', default: 0
      t.string 'accommodations', default: ''
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.datetime 'deleted_at'
      t.index ['deleted_at'], name: 'index_registrations_on_deleted_at'
      t.index %w[user_id event_id], name: 'index_registrations_on_user_id_and_event_id', unique: true
    end

    create_table 'suppliers', force: :cascade do |t|
      t.string 'name', null: false
      t.string 'url'
      t.string 'email'
      t.string 'address1'
      t.string 'address2'
      t.string 'city'
      t.string 'state'
      t.string 'zip'
      t.string 'province'
      t.string 'country'
      t.string 'phone'
      t.string 'poc_name'
      t.string 'poc_email'
      t.string 'poc_phone'
      t.string 'poc_address'
      t.text 'comments'
      t.datetime 'deleted_at'
      t.index ['name'], name: 'index_suppliers_on_name'
    end

    create_table 'technologies', force: :cascade do |t|
      t.string 'name', null: false
      t.string 'description'
      t.integer 'ideal_build_length'
      t.integer 'ideal_group_size'
      t.integer 'ideal_leaders'
      t.boolean 'family_friendly'
      t.float 'unit_rate'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.datetime 'deleted_at'
      t.string 'img_url'
      t.string 'info_url'
      t.string 'owner'
      t.integer 'people', default: 0, null: false
      t.integer 'lifespan_in_years', default: 0, null: false
      t.integer 'liters_per_day', default: 0
      t.text 'comments'
      t.integer 'monthly_production_rate', default: 1, null: false
      t.index ['deleted_at'], name: 'index_technologies_on_deleted_at'
    end

    create_table 'technologies_users', id: false, force: :cascade do |t|
      t.bigint 'user_id', null: false
      t.bigint 'technology_id', null: false
      t.index %w[technology_id user_id], name: 'index_technologies_users_on_technology_id_and_user_id'
      t.index %w[user_id technology_id], name: 'index_technologies_users_on_user_id_and_technology_id'
    end

    create_table 'users', force: :cascade do |t|
      t.string 'email', default: '', null: false
      t.string 'encrypted_password', default: '', null: false
      t.string 'reset_password_token'
      t.datetime 'reset_password_sent_at'
      t.datetime 'remember_created_at'
      t.integer 'sign_in_count', default: 0, null: false
      t.datetime 'current_sign_in_at'
      t.datetime 'last_sign_in_at'
      t.inet 'current_sign_in_ip'
      t.inet 'last_sign_in_ip'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'phone'
      t.boolean 'is_leader', default: false
      t.boolean 'is_admin', default: false
      t.date 'signed_waiver_on'
      t.integer 'primary_location_id'
      t.string 'fname'
      t.string 'lname'
      t.datetime 'deleted_at'
      t.string 'authentication_token', limit: 30
      t.boolean 'does_inventory', default: false
      t.boolean 'send_notification_emails', default: false
      t.boolean 'send_inventory_emails', default: false
      t.boolean 'email_opt_out', default: false
      t.index ['authentication_token'], name: 'index_users_on_authentication_token', unique: true
      t.index ['deleted_at'], name: 'index_users_on_deleted_at'
      t.index ['email'], name: 'index_users_on_email', unique: true
      t.index ['reset_password_token'], name: 'index_users_on_reset_password_token', unique: true
    end

    add_foreign_key 'events', 'locations'
    add_foreign_key 'events', 'technologies'
    add_foreign_key 'extrapolate_component_parts', 'components'
    add_foreign_key 'extrapolate_component_parts', 'parts'
    add_foreign_key 'extrapolate_material_parts', 'materials'
    add_foreign_key 'extrapolate_material_parts', 'parts'
    add_foreign_key 'extrapolate_technology_components', 'components'
    add_foreign_key 'extrapolate_technology_components', 'technologies'
    add_foreign_key 'extrapolate_technology_parts', 'parts'
    add_foreign_key 'extrapolate_technology_parts', 'technologies'
    add_foreign_key 'registrations', 'events'
    add_foreign_key 'registrations', 'users'
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The initial migration is not revertable'
  end
end
