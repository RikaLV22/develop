Rails.application.routes.draw do
  resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    get '/me', to: 'users#me'
  resources :organizations, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    get 'users', to: 'organizations#users'
  end
  resources :transactions, only: [:index, :show, :create, :update, :destroy]
  post "/login", to: "logins#create"
  resources :accounts, only: [:index, :show, :create] do
    patch 'add_balance', on: :member
    patch 'subtract_balance', on: :member
  end
  resources :banks, only: [:index]
end