Gem::Specification.new do |spec|
  spec.name     = "developer"
  spec.version  = "0.1.0"
  spec.authors  = ["CitySocial"]
  spec.summary  = "Developer app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "csv"
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
