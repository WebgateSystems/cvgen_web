Rails.application.routes.draw do
  devise_for :users

  get "locale/:locale", to: "locales#update", as: :locale

  namespace :admin do
    root to: "dashboard#show"
    resources :users, except: :show
    resources :themes, except: :show
  end

  namespace :jobseeker do
    root to: "dashboard#show"
    resources :themes, except: :show
    resources :profiles do
      resources :versions, only: %i[new create destroy]
    end
    get "cv", to: "cvs#show", as: :cv
    get "cv/preview", to: "cvs#preview", as: :cv_preview
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"
end
