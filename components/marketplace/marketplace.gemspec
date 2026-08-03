require_relative "lib/marketplace/version"

Gem::Specification.new do |spec|
  spec.name     = "marketplace"
  spec.version  = Marketplace::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Marketplace app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
