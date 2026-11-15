Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  mount Lookbook::Engine, at: "/lookbook" if Rails.env.development?

  post "/demo/ships", to: "pages#create"
  root "pages#show"
  get "*path", to: "pages#show", constraints: ->(request) { !request.path.start_with?("/rails", "/lookbook", "/assets", "/up") }
end
