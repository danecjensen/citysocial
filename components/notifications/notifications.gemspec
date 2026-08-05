require_relative "lib/notifications/version"

Gem::Specification.new do |spec|
  spec.name     = "notifications"
  spec.version  = Notifications::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Notifications app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
