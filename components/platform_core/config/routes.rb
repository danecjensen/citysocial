PlatformCore::Engine.routes.draw do
  get  "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"

  get    "/login",  to: "sessions#new", as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  # OAuth (Google). The request phase (POST /auth/:provider) is served by the
  # OmniAuth middleware; these map its GET redirect callback + failure back into
  # the app. (Google's authorization-code flow always redirects back via GET.)
  get "/auth/:provider/callback", to: "omniauth_callbacks#create",  as: :omniauth_callback
  get "/auth/failure",            to: "omniauth_callbacks#failure", as: :omniauth_failure

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
