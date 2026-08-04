Events::Engine.routes.draw do
  # Mounted at /events. The daily "top 10 this week" is the module home; the
  # searchable archive lives at /events/all; individual events at /events/e/:id.
  root to: "events#index"
  get "all", to: "events#all", as: :all
  get "e/:id", to: "events#show", as: :event
end
