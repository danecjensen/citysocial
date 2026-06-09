Restaurants::Engine.routes.draw do
  root to: "matchups#new"
  resources :matchups, only: %i[create]
  get "/leaderboard", to: "leaderboard#index"

  namespace :admin do
    resources :restaurants, only: %i[index create destroy]
  end
end
