Rails.application.routes.draw do
  root to: 'events#index'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users
  get 'users/:id/show', to: 'users#show', as: 'show_user'
  get 'users/:id/edit', to: 'users#edit', as: 'edit_user'
  patch 'users/:id', to: 'users#update', as: 'update_user'
  get :waiver, controller: :application

  get 'events/:id/attendance', to: 'events#attendance', as: 'event_attendance'

  get 'info', to: 'pages#info', as: 'info'

  resources :events do
    resources :registrations
  end

  # mount StripeEvent::Engine, at: '/stripe-events'

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # catch-all for bad url
  get "*path", to:  'pages#route_error'
end
