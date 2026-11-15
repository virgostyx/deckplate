Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?

  post "/demo/ships", to: "pages#create"
  resource :dashboard, only: %i[show update]
  get "csp", to: "csp#show"
  resource :profile, only: %i[show new create edit update]
  root "pages#show"
  get "*path", to: "pages#show", constraints: ->(request) { !request.path.start_with?("/rails", "/lookbook", "/assets", "/up") }
end
