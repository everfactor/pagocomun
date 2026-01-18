Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  # Payment Methods (non-admin)
  resources :payment_methods, only: [:create] do
    collection do
      get "finish_enrollment/:user_id/:unit_id", to: "payment_methods#finish", as: :finish_enrollment
    end
  end

  # Manage namespace
  namespace :manage do
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :organizations do
      resources :units
      resources :unit_imports, only: [:new, :create]
    end
    resources :users
    resources :bills, only: [:index, :show]
    resources :payments, only: [:index, :show]
  end

  # Admin namespace
  namespace :admin do
    root "dashboard#index"
    resources :dashboard, only: [:index]
    resources :organizations
    resources :users do
      member do
        patch :approve
        patch :reject
      end
    end
    resources :units
    resources :unit_imports, only: [:new, :create]
    resources :bills, only: [:index, :show]
    resources :payments, only: [:index, :show]
    resources :payment_methods
    resources :unit_assignments, path: "unit-assignments"
  end

  get "enroll/:token", to: "dashboard#index", as: :public_enrollment
  resources :dashboard, only: [:index]

  # Defines the root path route ("/")
  root "home#index"
end
