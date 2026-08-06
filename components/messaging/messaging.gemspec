require_relative "lib/messaging/version"

Gem::Specification.new do |spec|
  spec.name     = "messaging"
  spec.version  = Messaging::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Messaging app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
