Notifications::Engine.routes.draw do
  root to: "notifications#index"

  resources :notifications, path: "", only: [] do
    member { patch :read }
    collection { patch :read_all }
  end
end
