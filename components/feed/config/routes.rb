Feed::Engine.routes.draw do
  resources :posts, only: %i[index create show edit update destroy] do
    resources :comments, only: :create
    resource :reaction, only: :create
    resource :save, only: %i[create destroy]
    resources :poll_votes, only: :create, param: :option_id
  end
  root to: "posts#index"
end
