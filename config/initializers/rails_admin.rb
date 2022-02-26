# frozen_string_literal: true

require 'money-rails/rails_admin'
require 'rails_admin/adapters/active_record'
require 'application_record'

require 'application_helper'
require 'devise_helper'
require 'error_handler'
require 'application_controller'

# Discard actions
# if active, can be discarded
require Rails.root.join('lib', 'rails_admin', 'discardable.rb')

# if discarded, can be restored
require Rails.root.join('lib', 'rails_admin', 'restorable.rb')

# if discarded, can be destroyed
require Rails.root.join('lib', 'rails_admin', 'destroyable.rb')

# custom rails_admin dashboard
require Rails.root.join('lib', 'rails_admin', 'dashboard.rb')

# custom action to link to assemble pages
require Rails.root.join('lib', 'rails_admin', 'assemble.rb')

# custom action to link to assemble pages
require Rails.root.join('lib', 'rails_admin', 'edit_in_app.rb')

# custom field formats (e.g. number_with_delimiter)
require Rails.root.join('lib', 'rails_admin', 'custom_fields.rb')

RailsAdmin.config do |config|
  config.parent_controller = ApplicationController.to_s
  config.main_app_name = ['20 Liters', 'Admin']

  # Exclude these models RailsAdmin:
  excluded_models = %w[
    Assembly
    ActiveStorage::Attachment
    ActiveStorage::Blob
    ActiveStorage::VariantRecord
    Count
    Email
    Inventory
    OauthUser
    Organization
    Setups
  ].freeze

  excluded_models.each do |excluded_model|
    config.model excluded_model do
      visible false
    end
  end

  # Hide but don't exclude models which are needed as associations
  invisible_models = %w[
    Registration
  ].freeze

  invisible_models.each do |invisible_model|
    config.model invisible_model do
      visible { false }
    end
  end

  ## == Devise integration ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.authorize_with do |_controller|
    unless current_user&.admin_or_leader? || current_user&.is_oauth_admin?
      flash[:error] = 'You don\'t have permission to visit the Admin dashboard.'
      redirect_to main_app.root_path
    end
  end

  config.model 'User' do
    weight 0
    list do
      scopes %i[builders leaders inventoryists data_managers schedulers setup_crew admins active discarded]
      sort_by 'lname, fname'
      field :fname
      field :lname
      field :email
      field :primary_location
      field :registrations do
        column_width 80
        pretty_value do
          value.size
        end
      end
      field :events do
        column_width 80
        pretty_value do
          value.size
        end
      end
      field :role
    end

    show do
      group :default do
        field :name
        field :email
        field :phone do
          label 'Phone'
        end
        field :role
        field :email_opt_out, :true_is_bad_false_is_good
      end

      group 'Event Stats' do
        field :signed_waiver_on
        field :registrations do
          pretty_value { value.size }
        end
        field :events_attended do
          pretty_value { value.size }
        end
        field :events_skipped do
          pretty_value { value.size }
        end
        field :total_volunteer_hours do
          label 'Volunteer hours'
          pretty_value { precise(value) }
        end
        field :total_guests

        field :events_list do
          label 'Last 5 events'
        end
      end

      group 'Leader Stats' do
        field :events_led do
          pretty_value { value.size }
        end
        field :total_leader_hours do
          label 'Leader hours'
          pretty_value { precise(value) }
        end
        field :primary_location
        field :availability do
          visible { bindings[:object].is_leader? }
        end
      end

      group 'Leader Qualifications' do
        field :techs_qualified_html do
          label 'Qualifications'
        end

        field :role_html do
          label 'Roles'
          visible { bindings[:object].is_leader? }
        end
      end

      group 'System access' do
        field :has_password, :boolean
        field :sign_in_count
        field :last_sign_in_at, :date
      end
    end

    edit do
      group :default do
        field :fname
        field :lname
        field :email
        field :email_opt_out do
          # TODO: not true for VWF
          help 'Prevents ANY email from being sent; overrides settings in Permissions.<br />Is synced with Kindful and Mailchimp.'.html_safe
        end
        field :phone
        field :discarded_at, :date do
          help 'Discarding hides this user from lists.<br />Discarded users can be deleted.'.html_safe
          pretty_value do
            'Not discarded' if value.nil?
          end
          read_only true
        end
      end

      group 'Password reset' do
        field :has_password, :boolean do
          read_only true
          help 'Users don\'t have to set a password to register for a build.<br />But they need a password to login for other functions like doing inventory.'.html_safe
        end
        field :send_reset_password_email do
          help 'Send an email to the address on file with a link to reset their own password'
          render do
            bindings[:view].render partial: 'send_password_reset_email', locals: { field: self, view: bindings[:view], object: bindings[:object] }
          end
        end
        field :reset_password_sent_at do
          read_only true
        end
      end

      group 'Permissions' do
        field :is_leader do
          help 'If making a new leader, use "Save and edit" button to see additional leader options and settings.'
        end
        field :does_inventory
        field :send_inventory_emails do
          help 'Will get an email everytime an inventory is complete'
        end
        field :is_setup_crew do
          help 'Sets up the space for Events in advance'
        end
        field :is_scheduler do
          help 'Schedules Build Leaders for Events'
        end
        field :is_data_manager do
          help 'Adds Event Reports and manages User Communication Preferences'
        end
        field :send_notification_emails do
          help 'Will get an email everytime an event is created or changed'
        end
        field :is_admin do
          help 'Full access to all system functions. Admins can\'t be discarded or deleted.'
          read_only do
            # can't de-admin the first user
            bindings[:object].id == 1
          end
        end
      end

      group 'Leader details' do
        field :primary_location do
          visible { bindings[:object].is_leader? }
        end
        field :available_business_hours do
          visible { bindings[:object].is_leader? }
        end
        field :available_after_hours do
          visible { bindings[:object].is_leader? }
        end
        field :technologies do
          label 'Qualified to lead:'
          visible { bindings[:object].is_leader? }
          inline_add false
        end
      end
    end
  end

  config.model 'Event' do
    weight 1
    list do
      scopes %i[all needs_leaders future needs_report closed discarded]
      sort_by :start_time
      field :title
      field :format_date_w_year do
        label 'Date'
        column_width 110
      end
      field :format_time_slim do
        label 'Time'
        column_width 80
      end
      field :location
      field :needs_leaders?, :true_is_bad do
        column_width 80
      end
      field :leaders_have_vs_needed do
        label 'Leaders'
        column_width 80
      end
      field :builders_have_vs_total do
        label 'Builders'
        column_width 80
      end
      field :leaders_names_full do
        label 'Leaders'
      end
    end
  end

  config.model 'Technology' do
    weight 2

    configure :image do
      label 'Inventory Image'
    end

    configure :comments do
      label 'Admin notes'
    end

    configure :description do
      label 'Inventory description'
    end

    list do
      scopes %i[active discarded]
      sort_by :name
      field :name
      field :short_name
      field :owner do
        column_width 80
      end
      field :price, :money do
        formatted_value { bindings[:object].price }
        column_width 80
      end
      field :family_friendly do
        column_width 80
      end
      field :ideal_build_length do
        column_width 80
      end
      field :ideal_group_size do
        column_width 80
      end
      field :default_goal do
        column_width 80
      end
    end

    show do
      group :default do
        field :uid
        field :name
        field :short_name
        field :price, :money
        field :list_worthy do
          label 'Show on lists'
        end
        field :discarded_at, :date
      end

      group 'Inventory info' do
        field :description
        field :image, :active_storage
        field :available_count, :delimited
        field :only_loose
        field :loose_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :quantity_per_box, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_type do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_notes do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :can_be_produced, :delimited
        field :minimum_on_hand, :delimited
        field :below_minimum, :true_is_bad do
          visible do
            bindings[:object].below_minimum
          end
        end
        field :default_goald, :delimited do
          label 'Default production goal for cycle'
        end
        field :goal_remainder, :delimited
      end

      group 'Build info' do
        field :display_image, :active_storage
        field :info_url do
          formatted_value do
            fa_external_link(bindings[:view], value)
          end
        end
        field :public_description
        field :family_friendly
        field :ideal_build_length
        field :ideal_group_size
        field :ideal_leaders
        field :monthly_production_rate do
          label 'Should produce per month'
        end
        field :unit_rate do
          label 'Average built per builder per hour'
        end
      end

      group 'More details' do
        field :comments
        field :owner
        field :people do
          label 'People served'
        end
        field :lifespan_in_years
        field :liters_per_day
      end

      group 'Items' do
        field :quantities, :quantities_json
      end

      group 'History' do
        field :history_series, :line_chart
      end
    end

    edit do
      group :default do
        field :uid do
          help ''
          read_only true
        end
        field :name
        field :short_name
        field :price, :money do
          read_only true
          help 'Calculated from parts and materials'
        end
        field :list_worthy do
          help 'Un-check to hide from Inventory and Build dropboxes'
        end
        field :discarded_at, :date do
          help 'Discarding hides this technology from use'
          read_only true
        end
      end

      group 'Inventory info' do
        active false
        field :description
        field :image, :active_storage
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :only_loose do
          help 'Does not come in boxes or specific quantities'
        end
        field :loose_count do
          help 'Current loose count'
        end
        field :box_count do
          help 'Current box count'
        end
        field :quantity_per_box
        field :box_type do
          help 'Customize name. E.g. bag, bundle, large tub, medium tub, small tub, tray'
        end
        field :box_notes do
          help 'An extra field for things like: "quantity is an average", "red strap bundle is approx 100"'
        end
        field :can_be_produced, :delimited do
          help 'Calculated number that can be made'
          read_only true
        end
        field :minimum_on_hand do
          help 'Minimum inventory level to maintain'
        end
        field :default_goal do
          help 'Default production goal for cycle'
        end
        field :goal_remainder, :delimited do
          read_only true
        end
      end

      group 'Build info' do
        active false
        field :display_image, :active_storage
        field :info_url
        field :public_description
        field :family_friendly do
          help 'Builds are suitable for young kids?'
        end
        field :ideal_build_length
        field :ideal_group_size
        field :ideal_leaders
        field :monthly_production_rate do
          help 'Should produce per month'
        end
        field :unit_rate do
          help 'Average built per builder per hour'
        end
      end

      group 'More details' do
        active false
        field :comments
        field :owner
        field :people do
          help '# of people served by each'
        end
        field :lifespan_in_years do
          help 'How long one should last'
        end
        field :liters_per_day do
          help 'Liters produced from one'
        end
      end
    end
  end

  config.model 'Component' do
    parent 'Technology'
    weight 0

    configure :description do
      label 'Label description'
    end

    configure :comments do
      label 'Admin notes'
    end

    list do
      scopes %i[active discarded]
      sort_by :name
      field :uid do
        column_width 50
      end
      field :name
      field :price, :money
      field :available_count, :delimited do
        column_width 80
      end
      field :goal_remainder, :delimited do
        column_width 80
      end
    end

    show do
      group :default do
        field :uid_and_name do
          label 'UID: Name'
        end
        field :image, :active_storage
        field :comments
        field :description
        field :price, :money
      end
      group 'Inventory Info' do
        field :available_count, :delimited
        field :goal_remainder, :delimited
        field :only_loose
        field :loose_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :quantity_per_box, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_type do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_notes do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :below_minimum, :true_is_bad_false_is_good
        field :minimum_on_hand, :delimited
        field :can_be_produced, :delimited do
          help 'Calculated can be produced from sub items'
        end
        field :discarded_at, :date
      end

      group 'Quantities' do
        field :quantities, :quantities_json
      end

      group 'History' do
        field :history, :history_json
        field :history_series, :line_chart
      end
    end

    edit do
      group :default do
        field :uid do
          help ''
          read_only true
        end
        field :name
        field :image, :active_storage do
          delete_method :remove_image
        end
        field :comments
        field :description
        field :price, :money do
          help 'Calcuated from parts and materials'
          read_only true
        end
        field :discarded_at do
          help 'Discarding hides this component from use'
          read_only true
        end
      end

      group 'Inventory Info' do
        active false
        field :loose_count do
          help 'Current loose count'
        end
        field :only_loose do
          help 'Does not come in boxes or specific quantities'
        end
        field :box_count do
          help 'Current box count'
        end
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :quantity_per_box
        field :box_type do
          help 'Customize name. E.g. bag, bundle, large tub, medium tub, small tub, tray'
        end
        field :box_notes do
          help 'An extra field for things like: "quantity is an average", "red strap bundle is approx 100"'
        end
        field :minimum_on_hand
        field :below_minimum, :true_is_bad_false_is_good do
          read_only true
        end
        field :can_be_produced, :delimited do
          help 'Calculated can be produced from sub items'
          read_only true
        end
        field :goal_remainder, :delimited do
          help 'Calculated remainder needed to reach Technoloy goals'
          read_only true
        end
      end
    end
  end

  config.model 'Part' do
    parent 'Technology'
    weight 1

    configure :description do
      label 'Label Description'
    end

    configure :comments do
      label 'Admin notes'
    end

    list do
      scopes %i[active discarded]
      sort_by :name
      field :uid do
        column_width 50
      end
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
        column_width 120
      end
      field :order_url do
        column_width 80
        formatted_value do
          if value.present?
            fa_external_link(bindings[:view], value)
          else
            '&nbsp'.html_safe
          end
        end
      end
      field :price, :money
      field :available_count, :delimited do
        column_width 80
      end
      field :goal_remainder, :delimited do
        column_width 80
      end
      field :made_from_material, :false_is_invisible do
        column_width 80
      end
    end

    show do
      group :default do
        field :uid_and_name do
          label 'UID: Name'
        end
        field :image, :active_storage
        field :comments
        field :description
      end
      group 'Inventory Info' do
        field :available_count, :delimited
        field :goal_remainder, :delimited
        field :only_loose
        field :loose_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :quantity_per_box, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_type do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_notes do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :below_minimum, :true_is_bad_false_is_good
        field :minimum_on_hand, :delimited
        field :discarded_at, :date
      end
      group 'Supplier Info' do
        field :supplier_and_sku do
          label do
            'Supplier & SKU'
          end
        end
        field :price, :money
        field :min_order, :delimited
        field :weeks_to_deliver
        field :made_from_material
        field :material
        field :quantity_from_material
        field :can_be_produced, :delimited do
          help 'Calculated can be produced from sub items'
        end
      end
      group 'Order Info' do
        field :last_ordered_at, :date
        field :last_ordered_quantity, :delimited
        field :last_received_at, :date
        field :last_received_quantity, :delimited
      end

      group 'Quantities:' do
        field :quantities, :quantities_json
      end

      group 'History' do
        field :history, :history_json
        field :history_series, :line_chart
      end
    end

    edit do
      group :default do
        field :uid do
          help ''
          read_only true
        end
        field :name
        field :image, :active_storage do
          delete_method :remove_image
        end
        field :comments
        field :description
        field :made_from_material
        field :material do
          label 'Made from this material:'
        end
        field :quantity_from_material
        field :can_be_produced, :delimited do
          help 'Calculated can be produced from sub items'
          read_only true
        end
        field :discarded_at do
          help 'Discarding hides this part from use'
          read_only true
        end
      end
      group 'Inventory Info' do
        active false
        field :loose_count do
          help 'Current loose count'
        end
        field :only_loose do
          help 'Does not come in boxes or specific quantities'
        end
        field :box_count do
          help 'Current box count'
        end
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :quantity_per_box
        field :box_type do
          help 'Customize name. E.g. bag, bundle, large tub, medium tub, small tub, tray'
        end
        field :box_notes do
          help 'An extra field for things like: "quantity is an average", "red strap bundle is approx 100"'
        end
        field :minimum_on_hand
        field :below_minimum, :true_is_bad_false_is_good do
          read_only true
        end
        field :can_be_produced, :delimited do
          visible do
            bindings[:object].made_from_material?
          end
          help 'Calculated can be produced from materials'
          read_only true
        end
        field :goal_remainder, :delimited do
          help 'Calculated remainder needed to reach Technoloy goals'
          read_only true
        end
      end
      group 'Supplier Info' do
        active false
        field :supplier
        field :sku
        field :order_url
        field :price, :money
        field :min_order
        field :weeks_to_deliver
      end
      group 'Order Info' do
        active false
        field :last_ordered_at, :date
        field :last_ordered_quantity, :delimited
        field :last_received_at, :date
        field :last_received_quantity, :delimited
      end
    end
  end

  config.model 'Material' do
    parent 'Technology'
    weight 2

    configure :description do
      label 'Label Description'
    end

    configure :comments do
      label 'Admin notes'
    end

    list do
      scopes %i[active discarded]
      sort_by :name
      field :uid do
        column_width 50
      end
      field :name
      field :price, :money
      field :supplier do
        formatted_value { bindings[:object].name }
        column_width 100
      end
      field :order_url do
        column_width 80
        formatted_value do
          if value.present?
            fa_external_link(bindings[:view], value)
          else
            '&nbsp'.html_safe
          end
        end
      end
      field :available_count, :delimited do
        column_width 80
      end
      field :goal_remainder, :delimited do
        column_width 80
      end
      field :below_minimum, :true_is_bad do
        label 'Low?'
        column_width 80
      end
    end

    show do
      group :default do
        field :uid_and_name do
          label 'UID: Name'
        end
        field :image, :active_storage
        field :comments
        field :description
        field :parts
      end
      group 'Inventory Info' do
        field :available_count, :delimited
        field :goal_remainder, :delimited
        field :only_loose
        field :loose_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_count, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :quantity_per_box, :delimited do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_type do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :box_notes do
          visible do
            !bindings[:object].only_loose?
          end
        end
        field :below_minimum, :true_is_bad_false_is_good
        field :minimum_on_hand, :delimited
        field :discarded_at, :date
      end
      group 'Supplier Info' do
        field :supplier_and_sku do
          label do
            'Supplier & SKU'
          end
        end
        field :price, :money
        field :min_order, :delimited
        field :weeks_to_deliver
      end
      group 'Order Info' do
        field :last_ordered_at, :date
        field :last_ordered_quantity, :delimited
        field :last_received_at, :date
        field :last_received_quantity, :delimited
      end

      group 'Quantities:' do
        field :quantities, :quantities_json
      end

      group 'History' do
        field :history, :history_json
        field :history_series, :line_chart
      end
    end

    edit do
      group :default do
        field :uid do
          help ''
          read_only true
        end
        field :name
        field :image, :active_storage do
          delete_method :remove_image
        end
        field :comments
        field :description
        field :parts do
          label 'Makes these parts:'
        end
        field :discarded_at do
          help 'Discarding hides this material from use'
          read_only true
        end
      end
      group 'Inventory Info' do
        active false
        field :loose_count do
          help 'Current loose count'
        end
        field :only_loose do
          help 'Does not come in boxes or specific quantities'
        end
        field :box_count do
          help 'Current box count'
        end
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :quantity_per_box
        field :box_type do
          help 'Customize name. E.g. bag, bundle, large tub, medium tub, small tub, tray'
        end
        field :box_notes do
          help 'An extra field for things like: "quantity is an average", "red strap bundle is approx 100"'
        end
        field :minimum_on_hand
        field :below_minimum, :true_is_bad_false_is_good do
          read_only true
        end
        field :goal_remainder, :delimited do
          help 'Calculated remainder needed to reach Technoloy goals'
          read_only true
        end
      end
      group 'Supplier Info' do
        active false
        field :supplier
        field :sku
        field :order_url
        field :price, :money
        field :min_order
        field :weeks_to_deliver
      end
      group 'Order Info' do
        active false
        field :last_ordered_at, :date
        field :last_ordered_quantity, :delimited
        field :last_received_at, :date
        field :last_received_quantity, :delimited
      end
    end
  end

  config.model 'Supplier' do
    weight 3
    list do
      scopes %i[active discarded]
      sort_by :name
      field :name
      field :url do
        formatted_value do
          if value.present?
            fa_external_link(bindings[:view], value)
          else
            '&nbsp'.html_safe
          end
        end
      end
      field :parts do
        pretty_value do
          value.size
        end
      end
      field :materials do
        pretty_value do
          value.size
        end
      end
      field :poc_name
      field :poc_email
    end

    show do
      group :default do
        field :name
        field :comments
        field :url do
          pretty_value { external_link(bindings[:view], value) }
        end
        field :email
        field :phone
        field :address_block do
          label 'Address'
        end
        field :discarded_at
      end

      group 'Point of Contact' do
        field :poc_name
        field :poc_email
        field :poc_phone
        field :poc_address
      end

      group 'Parts' do
        field :parts do
          visible { value.any? }
        end
      end

      group 'Materials' do
        field :materials do
          visible { value.any? }
        end
      end
    end

    edit do
      group :default do
        field :name
        field :comments
        field :url
        field :email
        field :phone
        field :address1
        field :address2
        field :city
        field :state
        field :province
        field :zip
        field :country
        field :discarded_at do
          help 'Discarding hides this supplier from use'
          read_only true
        end
      end

      group 'Point of Contact' do
        active false
        field :poc_name
        field :poc_email
        field :poc_phone
        field :poc_address
      end

      group 'Items' do
        field :parts do
          sortable 'name'
        end
        field :materials do
          sortable 'name'
        end
      end
    end
  end

  config.model 'Location' do
    weight 4
    list do
      scopes %i[active discarded]
      sort_by :name
      field :name
      field :addr_one_liner do
        label 'Address'
      end
    end

    show do
      field :name
      field :instructions
      field :address_block do
        label 'Address'
      end
      field :discarded_at
      field :image, :active_storage
    end

    edit do
      field :name
      field :instructions
      field :address1
      field :address2
      field :city
      field :state
      field :zip
      field :discarded_at do
        help 'Discarding hides this location from use'
        read_only true
      end
      field :image, :active_storage
    end
  end

  config.actions do
    dashboard
    index # mandatory
    new
    export
    show do
      visible do
        !bindings[:object].instance_of?(Event) ||
          (bindings[:object].instance_of?(Event) &&
            bindings[:object].discarded?)
      end
    end
    edit do
      visible do
        !bindings[:object].instance_of?(Event)
      end
    end
    show_in_app do
      visible do
        bindings[:object].instance_of?(Event) &&
          !bindings[:object].discarded?
      end
    end
    edit_in_app do
      visible do
        bindings[:object].instance_of?(Event) &&
          !bindings[:object].discarded?
      end
    end
    discardable
    restorable
    destroyable do
      pjax { false }
    end
    assemble
  end

  def delimited(number)
    integer = number.instance_of?(String) ? number.to_i : number

    return '-' if integer.nil? || integer.zero?

    extend ActionView::Helpers::NumberHelper

    number_with_delimiter(integer, delimiter: ',')
  end

  def precise(number, precision = 2)
    float = number.instance_of?(String) ? number.to_f : number

    return '-' if float.nil? || float.zero?

    extend ActionView::Helpers::NumberHelper

    number_with_precision(float, precision: precision, delimiter: ',')
  end

  def external_link(view, link)
    view.link_to link, link, target: '_blank', rel: 'noopener noreferrer'
  end

  def fa_external_link(view, link)
    view.link_to link, target: '_blank', rel: 'noopener noreferrer' do
      "<i class='fa fa-external-link'></i>".html_safe
    end
  end
end
