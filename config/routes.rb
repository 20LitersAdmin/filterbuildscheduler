# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'events#index'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, controllers: { sessions: "sessions" }
  get 'users/:id/show', to: 'users#show', as: 'show_user'
  get 'users/:id/edit', to: 'users#edit', as: 'edit_user'
  get 'users/communication', to: 'users#communication', as: 'users_communication'
  put 'users/comm_complete', to: 'users#comm_complete', as: 'users_comm_complete'
  patch 'users/:id', to: 'users#update', as: 'update_user'
  get :waiver, controller: :application

  get 'info', to: 'pages#info', as: 'info'
  get 'report', to: 'pages#report', as: 'report'
  get 'vol_report', to: 'pages#vol_report', as: 'vol_report'
  get 'labels', to: 'counts#labels', as: 'labels'

  resources :events do
    collection do
      get 'cancelled'
      get 'closed'
      get 'lead'
    end
    member do
      get 'attendance'
      get 'restore'
      get 'poster'
      get 'leaders'
      get 'leader_unregister'
      get 'leader_register'
    end
    resources :registrations do
      collection do
        get 'restore'
        get 'messenger'
        post 'sender'
        get 'reconfirms'
      end
      member do
        get 'reconfirm'
      end
    end
  end

  resources :technologies, only: [:index] do
    member do
      get 'items'
    end
  end

  resources :inventories do
    collection do
      get 'order'
      get 'order_all'
      get 'status'
      get 'financials'
    end
    get 'paper', on: :member
    resources :counts do
      get 'label', on: :member
    end
  end

  post 'stripe-webhook', to: 'webhooks#receive', as: 'stripe_webhook'

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  # catch-all for bad urls
  get '*path', to:  'pages#route_error'
end
