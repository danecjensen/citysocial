require_relative "lib/feedback/version"

Gem::Specification.new do |spec|
  spec.name     = "feedback"
  spec.version  = Feedback::VERSION
  spec.authors  = ["CitySocial"]
  spec.summary  = "Feedback app-module."
  spec.files    = Dir["{app,config,lib}/**/*", "README.md"]
  spec.add_dependency "rails", "~> 7.2"
  spec.add_dependency "platform_core"
end
