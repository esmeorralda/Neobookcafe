Rails.application.routes.draw do
  get "sessions/new"
  get "sessions/create"
  get "sessions/destroy"
  get "users/show"
  get "users/edit"
  root "home#index"
  get "home/index"
  resources :users
  resources :thoughts
resources :discussions
resources :creations
resources :boards
resources :book_notes, only: [:new, :create]
resources :posts, only: [:new, :create]

get '/profile', to: 'users#show', as: 'profile'
  get '/settings', to: 'users#edit', as: 'settings'
  get '/login', to: 'sessions#new', as: 'login'

  # 나중에 로그인 POST 처리도 필요:
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
get '/signup', to: 'users#new', as: 'signup'
post '/users', to: 'users#create'



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
