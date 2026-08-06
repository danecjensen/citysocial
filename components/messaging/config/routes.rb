Messaging::Engine.routes.draw do
  resources :conversations, only: %i[index new create show] do
    resources :messages, only: :create
  end

  root to: "conversations#index"
end
