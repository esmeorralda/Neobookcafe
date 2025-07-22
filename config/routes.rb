Rails.application.routes.draw do
  get "reports/create"
  get "feedbacks/new"
  get "feedbacks/create"
  get "feedbacks/index"
  get "chapters/index"
  devise_for :users

  root "home#index"
  get "home/index"

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
    get 'chapters_and_current_page', on: :member
  end

  resources :notes

  resources :feedbacks, only: [:new, :create, :index]


  get '/search', to: 'posts#search', as: :search 

  resources :users, only: [:show] do
    member do
      get :my_posts
      get :liked_posts
      get :saved_posts
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
