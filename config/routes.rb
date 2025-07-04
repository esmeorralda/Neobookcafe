Rails.application.routes.draw do
  devise_for :users
  
  root "home#index"
  get "home/index"
  
  resources :users
  resources :thoughts
resources :discussions
resources :creations
resources :boards
resources :posts
resources :books do
  resources :notes, only: [:new, :create, :edit, :update, :destroy]
end
resources :books do
  resources :chapters, only: [:index]
end

resources :notes
resources :books


get '/profile', to: 'users#show', as: 'profile'
  get '/settings', to: 'users#edit', as: 'settings'

  # 나중에 로그인 POST 처리도 필요:




  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
