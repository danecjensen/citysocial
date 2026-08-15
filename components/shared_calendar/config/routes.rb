SharedCalendar::Engine.routes.draw do
  # The engine is mounted at /shared_calendar, so events live at the engine
  # root instead of repeating the word "events" in every URL.
  resources :events, path: ""
end
