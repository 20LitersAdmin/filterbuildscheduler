# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'events#index'

  devise_for :users, controllers: { sessions: 'sessions' }
  get 'users/:id/show', to: 'users#show', as: 'show_user'
  get 'users/:id/edit', to: 'users#edit', as: 'edit_user'
  get 'users/:id/edit_leader_notes', to: 'users#edit_leader_notes', as: 'edit_leader_notes'
  get 'users/communication', to: 'users#communication', as: 'users_communication'
  put 'users/comm_complete', to: 'users#comm_complete', as: 'users_comm_complete'
  get 'users/:id', to: 'users#update', as: 'user'
  patch 'users/:id', to: 'users#update', as: 'update_user'
  get 'users/:id/availability', to: 'users#availability', as: 'user_availability'
  get 'users/:id/admin_password_reset', to: 'users#admin_password_reset', as: 'user_admin_password_reset'
  get 'users/:id/leader_type', to: 'users#leader_type', as: 'user_leader_type'
  patch 'users/:id/comm_update', to: 'users#comm_update', as: 'user_comm_update'
  get :waiver, controller: :application

  get 'info', to: 'pages#info', as: 'info'
  get 'leaders', to: 'users#leaders', as: 'leaders'

  resources :combinations, only: %i[index show edit], param: :uid, constraints: { uid: Constants::UID::URL_REGEX } do
    # A common controller for Technology & Component
    # since all the CRUDding is happening in RailsAdmin
    # we only really need to manage assemblies here.
    collection do
      post 'item_search'
    end
    # standard routes for assemblies model
    # combination/:combination_uid/assemblies
    resources :assemblies
  end

  resources :report, only: [:index] do
    collection do
      get 'volunteers'
      get 'leaders'
    end
  end

  resources :events do
    collection do
      get 'lead'
    end
    member do
      get 'attendance'
      get 'leaders'
      get 'leader_unregister'
      get 'leader_register'
      get 'poster'
      get 'replicate'
      get 'replicate_occurrences'
      put 'replicator'
    end
    resources :registrations do
      collection do
        get 'messenger'
        post 'sender'
        get 'reconfirms'
        get 'restore_all'
      end
      member do
        get 'reconfirm'
        get 'restore'
      end
    end
  end

  # Technologies resources:
  get 'donation_list', to: 'technologies#donation_list', as: 'donation_list'
  get 'label/:uid', to: 'technologies#label', as: 'label'
  get 'labels', to: 'technologies#labels', as: 'labels'
  post 'labels_select', to: 'technologies#labels_select', as: 'labels_select'

  resources :inventories do
    collection do
      get 'history'
      get 'order_all'
      get 'order'
      get 'paper'
      get 'status'
    end
    resources :counts
  end

  get '/auth',                    to: 'oauth_users#index', as: :auth_index
  get '/auth/in',                 to: 'oauth_users#in', as: :auth_in
  get '/auth/:provider/callback', to: 'oauth_users#callback'
  get '/auth/out',                to: 'oauth_users#out', as: :auth_out
  get '/auth/failure',            to: 'oauth_users#failure'
  get '/auth/:id/status',         to: 'oauth_users#status', as: :auth_status
  get '/auth/:id/manual',         to: 'oauth_users#manual', as: :auth_manual
  patch '/auth/:id',              to: 'oauth_users#update', as: :auth_update

  post 'stripe-webhook', to: 'webhooks#stripe', as: 'stripe_webhook'

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
  mount ActionCable.server => '/cable'

  authenticated :user, ->(user) { user.is_admin? } do
    mount DelayedJobWeb, at: '/delayed_job'
  end
end
