# frozen_string_literal: true

require 'money-rails/rails_admin'
require 'rails_admin/adapters/active_record'
require 'application_record'
require 'user'
require 'event'
require 'registration'
require 'location'
require 'technology'
require 'supplier'
require 'component'
require 'part'
require 'material'
require 'count'
require 'inventory'
require 'extrapolate_component_part'
require 'extrapolate_material_part'
require 'extrapolate_technology_component'
require 'extrapolate_technology_part'
require 'extrapolate_technology_material'

require Rails.root.join('lib', 'rails_admin', 'restore.rb')
require Rails.root.join('lib', 'rails_admin', 'paranoid_delete.rb')

RailsAdmin.config do |config|
  config.parent_controller = ApplicationController.to_s
  config.main_app_name = ['20 Liters', 'Admin']
  config.excluded_models = ['ActiveStorage::Blob', 'ActiveStorage::Attachment']

  # Monkey patch to remove default_scope
  #
  require 'rails_admin/adapters/active_record'

  module RailsAdmin::Adapters::ActiveRecord
    def get(id)
      object = model.with_deleted.find(id)
      return unless object == scoped.where(primary_key => id).first

      AbstractObject.new object
    end

    def scoped
      model.unscoped
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

  config.model User do
    weight 0
    list do
      scopes %i[active leaders admins only_deleted]
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

  config.model Event do
    weight 1
    object_label_method :format_time_range
    list do
      scopes %i[active future past needs_report closed only_deleted]
      field :start_time
      field :end_time
      field :title
      field :location
      field :is_private
      field :leaders_names_full
    end

    exclude_fields :registrations, :users, :inventory
  end

  config.model Registration do
    weight 0
    parent Event
    list do
      scopes %i[active only_deleted]
      field :event
      field :user
      field :attended
      field :leader
      field :guests_registered
      field :guests_attended
    end
  end

  config.model Location do
    weight 1
    parent Event
    list do
      scopes %i[active only_deleted]
      field :name
      field :address1
      field :address2
      field :zip
    end
  end

  config.model Technology do
    weight 2
    list do
      scopes %i[active only_deleted]
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

    exclude_fields :components, :parts, :materials
  end

  config.model Component do
    parent Technology
    weight 0
    list do
      scopes %i[active only_deleted]
      field :uid do
        sortable :id
      end
      field :name
      field :technologies
      field :price, :money do
        formatted_value { bindings[:object].price }
      end
      field :completed_tech
    end
    # TODO: Extrapolate tables arent' searching by Part name??
    # edit do
    #   field :extrapolate_component_parts do
    #     queryable true
    #     searchable ['parts.name']
    #   end
    # end
    configure :description do
      label 'Label Description'
    end

    exclude_fields :parts, :counts, :technologies
  end

  config.model Part do
    parent Technology
    weight 1
    list do
      scopes %i[active only_deleted]
      field :uid do
        sortable :id
      end
      field :name
      field :supplier do
        formatted_value { bindings[:object].name }
      end
      field :cprice, :money do
        label 'Price'
        formatted_value { bindings[:object].cprice }
      end
      field :made_from_materials
      field :min_order
      field :weeks_to_deliver
    end
    configure :description do
      label 'Label Description'
    end

    exclude_fields :components, :materials, :counts, :technologies
  end

  config.model Material do
    parent Technology
    weight 2
    list do
      scopes %i[active only_deleted]
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

  config.model Supplier do
    weight 3
    list do
      scopes %i[active only_deleted]
      field :name
      field :url
      field :poc_name
      field :poc_email
    end
  end

  config.model Count do
    visible false
  end

  config.model Inventory do
    visible false
  end

  config.model ExtrapolateComponentPart do
    visible false
  end

  config.model ExtrapolateMaterialPart do
    visible false
  end

  config.model ExtrapolateTechnologyComponent do
    visible false
  end

  config.model ExtrapolateTechnologyPart do
    visible false
  end

  config.model ExtrapolateTechnologyMaterial do
    visible false
  end

  config.actions do
    dashboard # mandatory
    index     # mandatory
    new
    export
    bulk_delete
    show
    edit
    show_in_app
    paranoid_delete # lib/rails_admin/paranoid_delete.rb
    restore         # lib/rails_admin/restore.rb
  end
end
