# config/routes.rb
Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Define a namespace for your API versioning
  namespace :api do
    namespace :v1 do
      # Rutas para Wallets (billeteras)
      # GET /api/v1/addresses/:address
      # Queremos que la URL sea /api/addresses/:address, no /api/v1/wallets/:id
      # Usamos scope para cambiar el prefijo de la URL manteniendo el controlador
      scope "addresses" do
        get ":address", to: "wallets#show", as: :address_details
      end

      # Rutas para Transactions (transacciones)
      # POST /api/v1/transactions (para crear)
      # GET /api/v1/transactions/:uuid (para mostrar una específica)
      resources :transactions, only: [ :create, :show ], param: :uuid
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
