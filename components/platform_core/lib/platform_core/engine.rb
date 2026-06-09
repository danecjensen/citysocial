module PlatformCore
  class Engine < ::Rails::Engine
    isolate_namespace PlatformCore

    # Modules register their event subscriptions in their own engines.
    # The bus itself lives in the shared kernel so every module can reach it.
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
