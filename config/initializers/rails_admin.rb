# frozen_string_literal: true

require 'money-rails/rails_admin'
require 'rails_admin/adapters/active_record'

require Rails.root.join('lib', 'rails_admin', 'restore.rb')
require Rails.root.join('lib', 'rails_admin', 'paranoid_delete.rb')

RailsAdmin.config do |config|
  config.main_app_name = ['20 Liters', 'Admin']
  config.excluded_models = ['ActiveStorage::Blob', 'ActiveStorage::Attachment']

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  #
  # Monkey patch to remove default_scope
  # module RailsAdmin::Adapters::ActiveRecord
  #   def get(id)
  #     return unless object == scoped.where(primary_key => id).first

  #     AbstractObject.new object
  #   end

  #   def scoped
  #     model.unscoped
  #   end
  # end

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

  # config.model Reservation do
  #   weight 2
  #   parent Event
  #   list do
  #     field :name
  #     field :display_date do
  #       formatted_value { bindings[:object].display_date }
  #     end
  #     field :recurrence
  #     field :expire_time
  #     field :user do
  #       label 'Creator'
  #       formatted_value { bindings[:object].user.name }
  #     end
  #   end
  #   edit do
  #     group :first do
  #       field :name
  #     end
  #     group :day do
  #       label 'Reserve a specific timeframe'
  #       help 'To reserve a whole day, start at 12:00am and end at 11:59pm'
  #       field :start_time
  #       field :end_time
  #     end
  #     group :recurring do
  #       label 'Recurring reservation'
  #       field :recurring
  #       field :recurrence
  #       field :expire_date do
  #         help 'When does this reservation expire?'
  #       end
  #     end
  #     group :recurring_daily do
  #       label 'Daily recurring reservations'
  #       help 'What time each day should be reserved?'
  #       field :start_time_of_day
  #       field :end_time_of_day
  #     end
  #     group :recurring_weekly do
  #       label 'Weekly recurring reservations'
  #       help 'If the reservation is for a specific time every week, also fill out Start Time of Day and End Time of Day under Daily Recurring Reservations'
  #       field :day_of_week
  #     end
  #     group :recurring_monthly do
  #       label 'Monthly recurring reservations'
  #       help 'If the reservation is for a specific time every month, also fill out Start Time of Day and End Time of Day under Daily Recurring Reservations'
  #       field :date_of_month do
  #         help 'Use a number or text like "2nd Monday"'
  #       end
  #     end
  #     group :recurring_annually do
  #       label 'Annualy recurring reservations'
  #       help 'If the reservation is for a specific time, also fill out Start Time of Day and End Time of Day under Daily Recurring Reservations'
  #       field :date_of_year
  #     end
  #     exclude_fields :created_at, :updated_at, :user_id
  #   end
  # end

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

    exclude_fields :extrapolate_technology_parts, :extrapolate_technology_components
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

  config.model Component do
    weight 4
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
    configure :description do
      label 'Label Description'
    end

    exclude_fields :extrapolate_technology_components, :extrapolate_component_parts, :counts
  end

  config.model Part do
    weight 5
    list do
      scopes %i[active only_deleted]
      field :uid do
        sortable :id
      end
      field :name
      field :supplier
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

    exclude_fields :extrapolate_technology_parts, :extrapolate_component_parts, :extrapolate_material_parts, :counts
  end

  config.model Material do
    weight 6
    list do
      scopes %i[active only_deleted]
      field :uid do
        sortable :id
      end
      field :name
      field :supplier
      field :price, :money
      field :min_order
      field :weeks_to_deliver
      field :min_order
    end
    configure :description do
      label 'Label Description'
    end

    exclude_fields :extrapolate_material_parts, :counts
  end

  config.model Count do
    visible false
  end

  config.model Inventory do
    visible false
  end

  config.model ExtrapolateComponentPart do
    parent Component
    label 'Component <-> Part'
    label_plural 'Components <-> Parts'

    list do
      field :component
      field :part
      field :parts_per_component
      field :part_price, :money do
        formatted_value { bindings[:object].part_price }
      end
      field :price_per_component, :money do
        formatted_value { bindings[:object].price_per_component }
      end
    end
  end

  config.model ExtrapolateMaterialPart do
    parent Material
    label 'Material <-> Part'
    label_plural 'Materials <-> Parts'

    list do
      field :material
      field :part
      field :parts_per_material
      field :material_price, :money do
        formatted_value { bindings[:object].material_price }
      end
      field :part_price, :money do
        formatted_value { bindings[:object].part_price }
      end
    end
  end

  config.model ExtrapolateTechnologyComponent do
    parent Component
    label 'Technology <-> Component'
    label_plural 'Technologies <-> Components'

    list do
      field :component
      field :technology
      field :components_per_technology
      field :component_price, :money do
        formatted_value { bindings[:object].component_price }
      end
      field :price_per_technology, :money do
        formatted_value { bindings[:object].price_per_technology }
      end
      field :required
    end
  end

  config.model ExtrapolateTechnologyPart do
    parent Part
    label 'Technology <-> Part'
    label_plural 'Technologies <-> Parts'

    list do
      field :part
      field :technology
      field :parts_per_technology
      field :part_price, :money do
        formatted_value { bindings[:object].part_price }
      end
      field :price_per_technology, :money do
        formatted_value { bindings[:object].price_per_technology }
      end
      field :required
    end
  end

  config.model ExtrapolateTechnologyMaterial do
    parent Material
    label 'Technology <-> Material'
    label_plural 'Technologies <-> Materials'

    list do
      field :material
      field :technology
      field :materials_per_technology
      field :material_price, :money do
        formatted_value { bindings[:object].material_price }
      end
      field :price_per_technology, :money do
        formatted_value { bindings[:object].price_per_technology }
      end
      field :required
    end
  end

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
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
