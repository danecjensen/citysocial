require_relative "lib/communities/version"

Gem::Specification.new do |spec|
  spec.name     = "communities"
  spec.version  = Communities::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Communities app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
