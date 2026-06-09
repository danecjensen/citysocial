source "https://rubygems.org"

ruby ">= 3.2"

gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "rails", "~> 7.2"

# Identity: password hashing for has_secure_password (kernel-owned auth).
gem "bcrypt", "~> 3.1"

# Async + event bus transport
gem "redis", ">= 5.0"
gem "sidekiq", "~> 7.0"

# Modular-monolith boundary enforcement
gem "packwerk", "~> 3.0"

gem "bootsnap", require: false
gem "dotenv-rails"

# --- engines (path-mounted local packages) ---
# Every app-module lives in components/ and is wired in here by the
# `app_module` generator. platform_core is the shared kernel.
gem "feed",          path: "components/feed"
gem "platform_core", path: "components/platform_core"

group :development, :test do
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 7.0"
  gem "rubocop-rails", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
