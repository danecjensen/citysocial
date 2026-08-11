Rails.application.routes.draw do
  mount PickupSports::Engine => "/pickup_sports"
  mount Messaging::Engine => "/messaging"
  mount Notifications::Engine => "/notifications"
  mount Feedback::Engine => "/feedback"
  mount Events::Engine => "/events"
  mount Marketplace::Engine => "/marketplace"
  mount Communities::Engine => "/communities"
  mount Restaurants::Engine => "/restaurants"
  # The kernel owns identity, so auth routes (signup/login/logout) live in
  # platform_core and are mounted at the root.
  mount PlatformCore::Engine => "/"

  # Each app-module is a mountable engine. New modules are mounted here by
  # the `app_module` generator. Keep this list as the single map of the app.
  mount Feed::Engine => "/feed"

  # Living style guide for the shared design system (PlatformCore::Ui).
  get "/design", to: "design#show"
  get "/about", to: "about#show", as: :about

  root to: redirect("/feed")
end
