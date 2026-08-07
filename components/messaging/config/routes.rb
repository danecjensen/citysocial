Messaging::Engine.routes.draw do
  resources :conversations, only: %i[index new create show] do
    member do
      patch :archive
      patch :restore
    end
    resources :messages, only: :create
  end

  root to: "conversations#index"
end
