Rails.application.routes.draw do
  devise_for :users

  get "locale/:locale", to: "locales#update", as: :locale

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
end
