RailsAdmin.config do |config|

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

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
      field :sign_in_count
      field :last_sign_in_at
    end
  end

  config.model Event do
    list do
      scopes [nil, :only_deleted]
      field :start_time
      field :end_time
      field :title
      field :location
      field :is_private
      field :users
    end
  end

  config.model Location do
    exclude_fields :id, :map_url, :photo_url, :instructions, :created_at, :updated_at, :deleted_at
    list do
      scopes [nil, :only_deleted]
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
  end

  config.model Component do
    list do
      scopes [nil, :only_deleted]
      field :name
      field :common_id
      field :technologies
      field :completed_tech
      field :completed_tech_boxed
    end
  end

  config.model Material do
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
  end

  config.model Part do
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
  end

  config.model Registration do
    list do
      scopes [nil, :only_deleted]
      field :event
      field :user
      field :attended
      field :leader
      field :guests_registered
      field :guests_attended
    end
  end

  config.model Count do
    list do
      scopes [nil, :only_deleted]
      field :inventory
      field :component
      field :part
      field :material
      field :loose_count
      field :unopened_boxes_count
    end
  end

  config.model Inventory do
    exclude_fields :id, :deleted_at, :created_at, :updated_at
    list do
      scopes [nil, :only_deleted]
    end
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
