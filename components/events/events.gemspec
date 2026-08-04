require_relative "lib/events/version"

Gem::Specification.new do |spec|
  spec.name     = "events"
  spec.version  = Events::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Events app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
