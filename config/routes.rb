Rails.application.routes.draw do
  root to: 'events#index'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users
  get 'users/:id/show', to: 'users#show', as: 'show_user'
  get 'users/:id/edit', to: 'users#edit', as: 'edit_user'
  patch 'users/:id', to: 'users#update', as: 'update_user'
  get :waiver, controller: :application

  get 'events/:id/attendance', to: 'events#attendance', as: 'event_attendance'

  resources :events do
    resources :registrations
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  get "*path", to:  'locations#route_error'
end
