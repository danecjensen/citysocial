NeighborHelp::Engine.routes.draw do
  root to: "requests#index"

  resources :requests, only: %i[index show new create] do
    resource :claim, only: %i[create destroy]
    patch :complete, on: :member
    patch :cancel, on: :member
    resources :reports, only: :create
  end

  namespace :admin do
    resources :requests, only: %i[index update]
    root to: "requests#index"
  end
end
