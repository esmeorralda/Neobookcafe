Rails.application.routes.draw do
  get "filters/check"
  get "notifications/index"
  get "reports/create"
  get "feedbacks/new"
  get "feedbacks/create"
  get "feedbacks/index"
  get "chapters/index"
  devise_for :users

  root "home#index"
  get "home/index"

  get 'filters/check', to: 'filters#check', as: 'check_filters'


  resources :thoughts
  resources :discussions
  resources :creations
  resources :boards

  resources :posts do
    post 'bookmark', to: 'posts#bookmark'
    delete 'unbookmark', to: 'posts#unbookmark'

    # 🔹 중복 없이 한 곳에서 search 정의
    collection do
      get :search
    end

    resources :comments, only: [:create]
  end

  resources :posts do
  resources :reports, only: [:create]
end

resources :reports, only: [:create]
  resources :likes

  resources :books do
 
    resources :notes, only: [:new, :create, :edit, :update, :destroy]
    resources :chapters, only: [:index]
      member do
    get :chapters_and_current_page
  end
  end

  resources :notes

  resources :feedbacks, only: [:new, :create, :index]

  resources :posts do
  resources :comments, only: [:create, :update, :destroy]
end


  get '/search', to: 'posts#search', as: :search 

  resources :users, only: [:show] do
    member do
      get :my_posts
      get :drafted_posts
      get :liked_posts
      get :saved_posts
    end
  end

  # config/routes.rb

resources :comments do
  post 'like', to: 'likes#create', defaults: { likeable: 'Comment' }
  delete 'unlike', to: 'likes#destroy', defaults: { likeable: 'Comment' }
end

# config/routes.rb
resources :notifications, only: [:index] do
  member do
    patch :mark_as_read
  end
end


  get '/my_posts', to: 'users#my_posts'
  get '/liked_posts', to: 'users#liked_posts'
  get '/saved_posts', to: 'users#saved_posts'
  get '/settings', to: 'users#edit', as: 'settings'
  get '/feedback', to: 'feedbacks#new', as: 'feedback'
  get 'users/edit_intro', to: 'users#edit_intro', as: 'edit_intro'

  resources :users

  get "up" => "rails/health#show", as: :rails_health_check
end
