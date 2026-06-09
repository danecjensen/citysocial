Rails.application.routes.draw do
  # Each app-module is a mountable engine. New modules are mounted here by
  # the `app_module` generator. Keep this list as the single map of the app.
  mount Feed::Engine => "/feed"

  root to: redirect("/feed")
end
