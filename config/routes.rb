Rails.application.routes.draw do
  resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy]
  resources :organization_memberships, only: [:index, :create, :destroy]

  get "/me", to: "users#me"

  resources :organizations, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    get "users", to: "organizations#users"
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
  
  get "/health", to: "health#show"
  get "/health/user", to: "health#user", as: :health_user
  get "/health/organization",
      to: "health#organization",
      as: :health_organization
  get "/health/organization_users",
      to: "health#organization_users",
      as: :health_organization_users
  get "/health/personal_transactions",
      to: "health#personal_transactions",
      as: :health_personal_transactions
  get "/health/organization_transactions",
      to: "health#organization_transactions",
      as: :health_organization_transactions
  get "/health/personal_accounts",
      to: "health#personal_accounts",
      as: :health_personal_accounts
  get "/health/organization_accounts",
    to: "health#organization_accounts",
    as: :health_organization_accounts
  get "/health/banks",
    to: "health#banks",
    as: :health_banks
  get "/health/ai",
    to: "health#ai",
    as: :health_ai
  get "health/ai/status",
    to: "health#ai_status"

  get "/maintenance/status", to: "maintenance_status#show"

  namespace :admin do
    get "dashboard", to: "dashboard#show"

    resources :users, only: [:index, :show] do
      member do
        patch :suspend
        patch :restore
        post :force_logout
      end
    end

    resources :organizations, only: [:index, :show, :destroy]
    resources :transactions, only: [:index, :show]

    get "system/status", to: "system#status"
    get "system/errors", to: "system#errors"

    get "maintenance", to: "maintenance#show"
    patch "maintenance", to: "maintenance#update"
    post "maintenance/logout_all", to: "maintenance#logout_all"

    post "system/restart", to: "system#restart"

    get "api_monitor",
        to: "api_monitor#status",
        as: :admin_api_monitor
    patch "api_monitor/maintenance",
      to: "api_monitor#update_maintenance",
      as: :admin_api_monitor_maintenance

    get "logs",
        to: "logs#index",
        as: :logs

    get "resources", 
      to: "resources#show"
  end

  mount ActionCable.server => "/cable"
end