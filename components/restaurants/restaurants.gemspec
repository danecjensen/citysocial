require_relative "lib/restaurants/version"

Gem::Specification.new do |spec|
  spec.name     = "restaurants"
  spec.version  = Restaurants::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Restaurants app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
