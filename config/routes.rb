Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Payment Methods (non-admin)
  resources :payment_methods, only: [:create] do
    collection do
      get "finish_enrollment", to: "payment_methods#finish", as: :finish_enrollment
    end
  end

  # Admin namespace
  namespace :admin do
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :organizations
    resources :users
    resources :communities
    resources :units
    resources :bills, only: [:index, :show]
    resources :payments, only: [:index, :show]
    resources :payment_methods, only: [:index, :show]
    resources :unit_assignments, path: "unit-assignments"
  end

  # Defines the root path route ("/")
  root "home#index"
end
