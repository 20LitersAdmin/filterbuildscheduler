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
require Rails.root.join('lib', 'rails_admin', 'assemble.rb')

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
    MaterialsPart
    OauthUser
    Organization
  ].freeze

  invisible_models.each do |invisible_model|
    config.model invisible_model do
      visible false
    end
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
      field :ideal_leaders
    end
    configure :image do
      label 'Inventory Image'
    end

    exclude_fields :components, :parts, :materials
  end

  config.model 'Component' do
    parent 'Technology'
    weight 0
    list do
      scopes %i[active discarded]
      field :uid
      field :name
      field :price, :money
      field :available_count
    end
    configure :description do
      label 'Label Description'
    end

    exclude_fields :parts, :counts, :technologies
  end

  config.model 'Part' do
    parent 'Technology'
    weight 1

    configure :description do
      label 'Label Description'
    end

    list do
      scopes %i[active discarded]
      field :uid
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
        # column_width 120
      end
      field :order_url do
        formatted_value do
          bindings[:view].link_to bindings[:object].order_url, target: '_blank', rel: 'tooltip' do
            "<i class='fa fa-external-link'></i>
            <span style='display:none'>Visit</span>
            ".html_safe
          end
        end
      end
      field :price, :money
      field :made_from_materials do
        column_width 80
        pretty_value { false_is_invisible(bindings[:object].made_from_materials) }
      end
      field :below_minimum do
        label 'Low?'
        column_width 80
        pretty_value { true_is_bad_and_false_is_invisible(bindings[:object].below_minimum) }
      end
    end
    configure :description do
      label 'Label Description'
    end

    edit do
      configure :image, :active_storage do
        delete_method :remove_image
      end
    end

    exclude_fields :components, :materials, :counts, :technologies
  end

  config.model 'Material' do
    parent 'Technology'
    weight 2

    configure :description do
      label 'Label Description'
    end

    list do
      scopes %i[active discarded]
      field :uid
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
      end
      field :order_url do
        formatted_value do
          bindings[:view].link_to bindings[:object].order_url, target: '_blank', rel: 'tooltip' do
            "<i class='fa fa-external-link'></i>
            <span style='display:none'>Visit</span>
            ".html_safe
          end
        end
      end
      field :price, :money
      field :min_order
    end

    show do
      group :default do
        field :uid_and_name do
          label 'UID: Name'
        end
        field :image, :active_storage
        field :comments do
          label 'Admin notes'
        end
        field :description do
          label 'Label description'
        end
      end
      group 'Inventory Info' do
        field :loose_count
        field :only_loose
        field :box_count
        field :available_count
        field :minimum_on_hand
        field :below_minimum
        field :discarded_at
      end
      group 'Supplier Info' do
        field :supplier do
          label do
            'Supplier & SKU'
          end
          pretty_value do
            "#{bindings[:object].supplier.name}&nbsp;&nbsp;&nbsp;&nbsp; SKU:#{bindings[:view].link_to bindings[:object].sku, bindings[:object].order_url, target: '_blank', rel: 'tooltip'}".html_safe
          end
        end
        field :price, :money
        field :min_order
        field :quantity_per_box
        field :weeks_to_deliver
      end
      group 'Order Info' do
        field :last_ordered_at
        field :last_ordered_quantity
        field :last_received_at
        field :last_received_quantity
      end

      field :price, :money
      field :min_order
      field :weeks_to_deliver
      field :quantity_per_box

      exclude_fields :name, :uid, :history, :quantities, :parts, :price_cents, :price_currency, :order_url, :sku, :materials_parts
    end

    edit do
      exclude_fields :history, :quantities, :parts, :price_cents, :price_currency
      group :default do
        field :name
        field :comments do
          label 'Admin notes'
        end
        field :description do
          label 'Label description'
        end
        field :uid do
          read_only true
        end
        field :image, :active_storage do
          delete_method :remove_image
        end
      end
      group 'Inventory Info' do
        active false
        field :loose_count
        field :only_loose
        field :box_count
        field :available_count
        field :minimum_on_hand
        field :below_minimum
        field :discarded_at do
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
        field :quantity_per_box
        field :weeks_to_deliver
      end
      group 'Order Info' do
        active false
        field :last_ordered_at
        field :last_ordered_quantity
        field :last_received_at
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

  # pretty_value styling for rails_admin booleans
  def true_is_bad(boolean)
    # e.g. component.below_minimum?
    case boolean
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(<span class='label label-success'>&#x2718;</span>)
    when true
      %(<span class='label label-danger'>&#x2713;</span>)
    end.html_safe
  end

  # pretty_value styling for rails_admin booleans
  def false_is_invisible(boolean)
    # e.g. component.made_from_materials?
    case boolean
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(&nbsp)
    when true
      %(<span class='label label-success'>&#x2713;</span>)
    end.html_safe
  end

  # pretty_value styling for rails_admin booleans
  def true_is_bad_and_false_is_invisible(boolean)
    # e.g. component.below_minimum?
    case boolean
    when nil
      %(<span class='label label-default'>&#x2012;</span>)
    when false
      %(&nbsp)
    when true
      %(<span class='label label-danger'>&#x2713;</span>)
    end.html_safe
  end
end
