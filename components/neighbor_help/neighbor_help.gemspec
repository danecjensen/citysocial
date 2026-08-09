require_relative "lib/neighbor_help/version"

Gem::Specification.new do |spec|
  spec.name     = "neighbor_help"
  spec.version  = NeighborHelp::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "NeighborHelp app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
