PickupSports::Engine.routes.draw do
  root to: "games#index"

  resources :games, only: %i[index show new create edit update] do
    patch :cancel, on: :member
    patch :close_attendance, on: :member
    resource :roster_entry, only: %i[create destroy]
    resources :roster_entries, only: [] do
      patch :attendance, on: :member
    end
  end
end
