module Feed
  class Engine < ::Rails::Engine
    isolate_namespace Feed

    config.after_initialize do
      Feed::Events.subscribe!
    end

    config.generators { |g| g.test_framework :rspec }
  end
end
