PlatformCore::Engine.routes.draw do
  get  "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"

  get    "/login",  to: "sessions#new", as: :login
  post   "/login",  to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
end
