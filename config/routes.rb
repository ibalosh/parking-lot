Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api, defaults: { format: :json } do
    resources :tickets, only: [ :create, :index, :show, :update ] do
      resource :payments, only: [ :create ]
      member do
        get :state
      end
    end
    get "free-spaces", to: "free_spaces#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
