source "https://rubygems.org"

ruby ">= 3.2"

gem "rails", "~> 7.2"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"

# Async + event bus transport
gem "sidekiq", "~> 7.0"
gem "redis", ">= 5.0"

# Modular-monolith boundary enforcement
gem "packwerk", "~> 3.0"

gem "bootsnap", require: false
gem "dotenv-rails"

# --- engines (path-mounted local packages) ---
# Every app-module lives in components/ and is wired in here by the
# `app_module` generator. platform_core is the shared kernel.
gem "platform_core", path: "components/platform_core"
gem "feed",          path: "components/feed"

group :development, :test do
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "rubocop-rails", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
