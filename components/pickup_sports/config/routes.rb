PickupSports::Engine.routes.draw do
  root to: "games#index"

  resources :games, only: %i[index show new create edit update] do
    patch :cancel, on: :member
    resource :roster_entry, only: %i[create destroy]
  end
end
