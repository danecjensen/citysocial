PlatformCore::Engine.routes.draw do
  get  "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"

  get    "/login",  to: "sessions#new", as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get   "/people/:handle", to: "profiles#show", as: :profile
  get   "/profile/edit", to: "profiles#edit", as: :edit_profile
  patch "/profile", to: "profiles#update"

  # The admin area is a single page; the per-resource routes below are the
  # actions its sections post to.
  namespace :admin do
    root to: "dashboard#show"
    resources :users, only: %i[update destroy]
    resources :modules, only: %i[update], param: :key
  end
end
