require_relative "lib/platform_core/version"

Gem::Specification.new do |spec|
  spec.name        = "platform_core"
  spec.version     = PlatformCore::VERSION
  spec.authors     = ["CitySocial"]
  spec.summary     = "Shared kernel: identity, social graph, and the event bus."
  spec.files       = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "view_component"
end
