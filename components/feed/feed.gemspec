require_relative "lib/feed/version"

Gem::Specification.new do |spec|
  spec.name     = "feed"
  spec.version  = Feed::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Hyperlocal feed app-module (reference implementation)."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
