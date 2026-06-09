Feed::Engine.routes.draw do
  resources :posts, only: %i[index create]
  root to: "posts#index"
end
