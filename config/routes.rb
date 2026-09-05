Rails.application.routes.draw do
  resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  get '/me', to: 'users#me'

  resources :organizations, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    get 'users', to: 'organizations#users'
  end

  resources :organization_transactions,
            controller: :organization_transactions do
    collection do
      get :summary
      get :history_summary
    end
  end

  resources :personal_transactions,
            controller: :personal_transactions do
    collection do
      get :summary
      get :history_summary
    end
  end

  post "/login", to: "logins#create"

  resources :personal_accounts,
            controller: :personal_accounts,
            only: [:index, :show, :create] do
    collection do
      post :transfer
    end

    member do
      patch :add_balance
      patch :subtract_balance
    end
  end

  resources :organization_accounts,
            controller: :organization_accounts,
            only: [:index, :show, :create] do
    collection do
      post :transfer
    end

    member do
      patch :add_balance
      patch :subtract_balance
    end
  end

  resources :banks, only: [:index]

  post "/chat", to: "chat#create"
  post "/personal_chat", to: "personal_chat#create"
end