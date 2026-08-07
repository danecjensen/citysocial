require_relative "lib/pickup_sports/version"

Gem::Specification.new do |spec|
  spec.name     = "pickup_sports"
  spec.version  = PickupSports::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "PickupSports app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
