Rails.application.routes.draw do
  # The kernel owns identity, so auth routes (signup/login/logout) live in
  # platform_core and are mounted at the root.
  mount PlatformCore::Engine => "/"

  # Each app-module is a mountable engine. New modules are mounted here by
  # the `app_module` generator. Keep this list as the single map of the app.
  mount Feed::Engine => "/feed"

  root to: redirect("/feed")
end
