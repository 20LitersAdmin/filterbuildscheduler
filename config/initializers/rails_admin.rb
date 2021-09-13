# frozen_string_literal: true

require 'money-rails/rails_admin'
require 'rails_admin/adapters/active_record'
require 'application_record'

require 'application_helper'
require 'devise_helper'
require 'error_handler'
require 'application_controller'

require Rails.root.join('lib', 'rails_admin', 'restore.rb')
require Rails.root.join('lib', 'rails_admin', 'discard.rb')
# custom rails_admin dashboard
require Rails.root.join('lib', 'rails_admin', 'dashboard.rb')
# custom action to link to assemble pages
require Rails.root.join('lib', 'rails_admin', 'assemble.rb')
# custom field formats (e.g. number_with_delimiter)
require Rails.root.join('lib', 'rails_admin', 'custom_fields.rb')

# NERF: this was to try to make rails_admin handle Assembly CRUD-ing through Component
# module RailsAdmin::Adapters::ActiveRecord
#   class Association
#     # monkey patch Component#assemblies complex has_many with lambda
#     def read_only?
#       return false if association.active_record == Component && association.klass == Assembly

#       (klass.all.instance_eval(&scope).readonly_value if scope.is_a? Proc) ||
#         association.nested? ||
#         false
#     end
#   end
# end

RailsAdmin.config do |config|
  config.parent_controller = ApplicationController.to_s
  config.main_app_name = ['20 Liters', 'Admin']

  # Hide these models from navigation pane:
  invisible_models = %w[
    Assembly
    ActiveStorage::Attachment
    ActiveStorage::Blob
    ActiveStorage::VariantRecord
    Count
    Email
    Inventory
    OauthUser
    Organization
  ].freeze

  invisible_models.each do |invisible_model|
    config.model invisible_model do
      visible false
    end
  end

  config.model 'MaterialsPart' do
    # this model can't be fully excluded or it breaks the nested form capabilities
    visible { false }
  end

  ## == Devise integration ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.authorize_with do |_controller|
    redirect_to main_app.root_path unless current_user&.is_admin?
  end

  config.model 'User' do
    weight 0
    list do
      scopes %i[active leaders builders inventoryists admins discarded]
      field :email
      field :fname
      field :lname
      field :primary_location
      field :is_leader
      field :does_inventory
      field :is_admin
      field :send_notification_emails
      field :sign_in_count
      field :last_sign_in_at
    end

    exclude_fields :registrations, :counts
  end

  config.model 'Event' do
    weight 1
    object_label_method :format_time_range
    list do
      scopes %i[active future past needs_report closed discarded]
      field :start_time
      field :end_time
      field :title
      field :location
      field :is_private
      field :leaders_names_full
    end

    exclude_fields :registrations, :users, :inventory
  end

  config.model 'Registration' do
    weight 0
    parent Event
    list do
      scopes %i[active discarded]
      field :event
      field :user
      field :attended
      field :leader
      field :guests_registered
      field :guests_attended
    end
  end

  config.model 'Location' do
    weight 1
    parent Event
    list do
      scopes %i[active discarded]
      field :name
      field :address1
      field :address2
      field :zip
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

    list do
      scopes %i[active discarded]
      field :name
      field :owner
      field :price, :money do
        formatted_value { bindings[:object].price }
      end
      field :family_friendly
      field :ideal_build_length
      field :ideal_group_size
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
        field :owner
        field :people do
          label 'People served'
        end
        field :lifespan_in_years
        field :liters_per_day
        field :discarded_at, :date
        field :info_url do
          formatted_value do
            fa_external_link(bindings[:view], value)
          end
        end
        field :monthly_production_rate do
          label 'Should produce per month'
        end
      end

      group 'Images and Descriptions' do
        field :image, :active_storage
        field :display_image, :active_storage
        field :description
        field :comments
      end

      group 'Inventory info' do
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
      end

      group 'Build info' do
        field :family_friendly
        field :ideal_build_length
        field :ideal_group_size
        field :ideal_leaders
        field :unit_rate
      end

      group 'History' do
        field :history, :line_chart
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
        field :image, :active_storage
        field :display_image, :active_storage

        field :list_worthy do
          help 'Un-check to hide from Inventory and Build dropboxes'
        end
        field :info_url
      end

      group 'Inventory info' do
        active false
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
      end

      group 'Build info' do
        active false
        field :family_friendly do
          help 'Builds are good for young kids?'
        end
        field :ideal_build_length
        field :ideal_group_size
        field :ideal_leaders
        field :monthly_production_rate do
          help 'Need produced every month'
        end
        field :unit_rate do
          help 'Average that can be built per builder per hour'
        end
      end

      group 'More details' do
        active false
        field :description
        field :comments
        field :price, :money do
          read_only true
          help 'Calculated from parts and materials'
        end
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
        field :discarded_at, :date do
          help 'Discarding hides this technology from use'
          read_only true
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
      field :uid do
        column_width 50
      end
      field :name
      field :price, :money
      field :available_count
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
        field :discarded_at, :date
      end

      group 'History' do
        field :history, :line_chart
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
        field :quantity_per_box
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :discarded_at do
          help 'Discarding hides this component from use'
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
        label 'Available'
        column_width 80
      end
      field :below_minimum, :true_is_bad do
        label 'Low?'
        column_width 80
      end
      field :made_from_materials, :false_is_invisible do
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
        field :minimum_on_hand, :delimited
        field :below_minimum
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
        field :last_ordered_quantity
        field :last_received_at, :date
        field :last_received_quantity
      end

      group 'History' do
        field :history, :line_chart
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
        field :made_from_materials
        field :materials_parts do
          label 'Made from this material:'
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
        field :quantity_per_box
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :minimum_on_hand
        field :discarded_at do
          help 'Discarding hides this part from use'
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
        field :last_ordered_at do
          label 'Last ordered'
        end
        field :last_ordered_quantity
        field :last_received_at do
          label 'Last received'
        end
        field :last_received_quantity
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
        label 'Available'
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
      end
      group 'Inventory Info' do
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
        field :minimum_on_hand, :delimited
        field :below_minimum
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
        field :last_ordered_quantity
        field :last_received_at, :date
        field :last_received_quantity
      end

      group 'History' do
        field :history, :line_chart
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
        field :materials_parts do
          label 'Makes these parts:'
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
        field :quantity_per_box
        field :available_count, :delimited do
          help 'Calculated total available'
          read_only true
        end
        field :minimum_on_hand
        field :below_minimum do
          read_only true
        end
        field :discarded_at do
          help 'Discarding hides this material from use'
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
        field :last_ordered_at do
          label 'Last ordered'
        end
        field :last_ordered_quantity
        field :last_received_at do
          label 'Last received'
        end
        field :last_received_quantity
      end
    end
  end

  config.model 'Supplier' do
    weight 3
    list do
      scopes %i[active discarded]
      field :name
      field :url
      field :poc_name
      field :poc_email
    end
  end

  config.actions do
    dashboard
    index # mandatory
    new
    export
    bulk_delete
    show
    edit
    show_in_app
    discard     # lib/rails_admin/discard.rb
    restore     # lib/rails_admin/restore.rb
    assemble
  end

  def delimited(number)
    integer = number.instance_of?(String) ? number.to_i : number

    return '-' if integer.nil? || integer.zero?

    extend ActionView::Helpers::NumberHelper

    number_with_delimiter(integer, delimiter: ',')
  end

  def fa_external_link(view, link)
    view.link_to link, target: '_blank', rel: 'noopener noreferrer' do
      "<i class='fa fa-external-link'></i>".html_safe
    end
  end
end
