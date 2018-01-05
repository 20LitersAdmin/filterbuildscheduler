RailsAdmin.config do |config|
  config.main_app_name = ["20 Liters", "Admin"]

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  #
  # Monkey patch to remove default_scope
  require 'rails_admin/adapters/active_record'
  module RailsAdmin::Adapters::ActiveRecord
    def get(id)
      return unless object = scoped.where(primary_key => id).first
      AbstractObject.new object
    end
    def scoped
      model.unscoped
    end
  end

  ## == Cancan ==
  # config.authorize_with :cancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.authorize_with do |controller|
    redirect_to main_app.root_path unless current_user&.is_admin?
  end

  config.model User do
    list do
      scopes [nil, :only_deleted]
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
    configure :deleted_at do
      show
    end

    exclude_fields :registrations, :counts
  end

  config.model Event do
    object_label_method :format_time_range
    list do
      scopes [nil, :only_deleted]
      field :start_time
      field :end_time
      field :title
      field :location
      field :is_private
      field :leaders_names_full
    end
    configure :deleted_at do
      show
    end

    exclude_fields :registrations, :users, :inventory
  end

  config.model Location do
    parent Event
    list do
      scopes [nil, :only_deleted]
      field :name
      field :address1
      field :address2
      field :zip
    end
    configure :deleted_at do
      show
    end
  end

  config.model Technology do
    list do
      scopes [nil, :only_deleted]
      field :name
      field :family_friendly
      field :unit_rate
      field :ideal_build_length
      field :ideal_group_size
      field :ideal_leaders
    end
    configure :deleted_at do
      show
    end

    exclude_fields :extrapolate_technology_parts, :extrapolate_technology_components
  end

  config.model Component do
    parent Technology
    list do
      scopes [nil, :only_deleted]
      field :name
      field :common_id
      field :technologies
      field :completed_tech
    end
    configure :deleted_at do
      show
    end

    exclude_fields :extrapolate_technology_components, :extrapolate_component_parts, :counts
  end

  config.model Material do
    parent Technology
    list do
      scopes [nil, :only_deleted]
      field :name
      field :supplier
      field :min_order
      field :weeks_to_deliver
      field :price_cents do
        label "Price"
        formatted_value do
          "$" + (value.to_f / 100).to_s
        end
      end
      field :min_order
    end
    configure :deleted_at do
      show
    end

    exclude_fields :extrapolate_material_parts, :counts
  end

  config.model Part do
    parent Technology
    list do
      scopes [nil, :only_deleted]
      field :name
      field :supplier
      field :min_order
      field :weeks_to_deliver
      field :price_cents do
        label "Price"
        formatted_value do
          "$" + (value.to_f / 100).to_s
        end
      end
    end
    configure :deleted_at do
      show
    end

    exclude_fields :extrapolate_technology_parts, :extrapolate_component_parts, :extrapolate_material_parts, :counts
  end

  config.model Registration do
    parent Event
    list do
      scopes [nil, :only_deleted]
      field :event
      field :user
      field :attended
      field :leader
      field :guests_registered
      field :guests_attended
    end
    configure :deleted_at do
      show
    end
  end

  config.model Count do
    visible false
  end

  config.model Inventory do
    visible false
  end

  config.model ExtrapolateComponentPart do
    parent Component
    label "Component <-> Part"
    label_plural "Components <-> Parts"
  end

  config.model ExtrapolateMaterialPart do
    parent Material
    label "Material <-> Part"
    label_plural "Materials <-> Parts"
  end

  config.model ExtrapolateTechnologyComponent do
    parent Technology
    label "Technology <-> Component"
    label_plural "Technologies <-> Components"
  end

  config.model ExtrapolateTechnologyPart do
    parent Technology
    label "Technology <-> Part"
    label_plural "Technologies <-> Parts"
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    clone
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
