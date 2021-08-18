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
require Rails.root.join('lib', 'rails_admin', 'dashboard.rb')

RailsAdmin.config do |config|
  config.parent_controller = ApplicationController.to_s
  config.main_app_name = ['20 Liters', 'Admin']

  # TODO: Second deploy delete for good
  # Monkey patch to remove default_scope
  #
  # require 'rails_admin/adapters/active_record'

  # module RailsAdmin::Adapters::ActiveRecord
  #   def get(id)
  #     object = model.with_deleted.find(id)
  #     return unless object == scoped.where(primary_key => id).first

  #     AbstractObject.new object
  #   end

  #   def scoped
  #     model.unscoped
  #   end
  # end

  ## == Devise integration ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  config.authorize_with do |_controller|
    redirect_to main_app.root_path unless current_user&.is_admin?
  end

  # pretty_value styling for booleans
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
    list do
      scopes %i[active discarded]
      field :uid
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
        column_width 120
      end
      field :available_count do
        label 'Avail'
        column_width 80
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
    list do
      scopes %i[active discarded]
      field :uid do
        sortable :id
      end
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
      end
      field :price, :money
      field :min_order
      field :weeks_to_deliver
      field :min_order
    end
    configure :description do
      label 'Label Description'
    end

    exclude_fields :parts, :counts, :technologies
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

  # Hide these models from navigation pane:
  invisible_models = %w[
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
  end
end
