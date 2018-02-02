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
    end
    resources :registrations do
      collection do
        get 'restore'
        get 'messenger'
        post 'sender'
      end
    end
  end

  resources :inventories do
    resources :counts
  end

  # mount StripeEvent::Engine, at: '/stripe-events'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # catch-all for bad url
  get "*path", to:  'pages#route_error'
end
