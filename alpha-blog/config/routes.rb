Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'pages#home'
  get '/about', to: 'pages#about'

  get 'signup', to: 'users#new'
  resources :users, except: [:new]

  #create resourful routes for categories
  resources :categories

  #create routes for login/logout
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  #creating resourful routes for articles
  resources :articles
end
