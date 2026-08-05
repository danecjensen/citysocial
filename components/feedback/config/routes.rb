Feedback::Engine.routes.draw do
  resources :submissions, only: %i[index show new create] do
    post :toggle_support, on: :member
  end

  namespace :admin do
    resources :submissions, only: %i[index update]
    root to: "submissions#index"
  end

  root to: "submissions#index"
end
