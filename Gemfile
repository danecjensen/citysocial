source "https://rubygems.org"

ruby ">= 3.2"

gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "rails", "~> 7.2"

# Front end: no-Node asset pipeline + shared design system
gem "importmap-rails"
gem "propshaft"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.0"
gem "turbo-rails"
gem "view_component"

# Identity: password hashing for has_secure_password (kernel-owned auth).
gem "bcrypt", "~> 3.1"

# Identity: "Sign in with Google" via OmniAuth (kernel-owned auth), plus CSRF
# protection for the OAuth request phase (button_to POST to /auth/:provider).
gem "omniauth-google-oauth2", "~> 1.1"
gem "omniauth-rails_csrf_protection", "~> 1.0"

# Async + event bus transport
gem "redis", ">= 5.0"
gem "sidekiq", "~> 7.0"

# Modular-monolith boundary enforcement
gem "packwerk", "~> 3.0"

gem "bootsnap", require: false
gem "dotenv-rails"

# Active Storage on S3 in production (Heroku Bucketeer addon provisions the
# bucket + credentials). Disk storage is ephemeral on Heroku's dynos.
gem "aws-sdk-s3", require: false

# --- engines (path-mounted local packages) ---
# Every app-module lives in components/ and is wired in here by the
# `app_module` generator. platform_core is the shared kernel.
gem "communities", path: "components/communities"
gem "developer", path: "components/developer"
gem "events", path: "components/events"
gem "feed", path: "components/feed"
gem "feedback", path: "components/feedback"
gem "marketplace", path: "components/marketplace"
gem "messaging", path: "components/messaging"
gem "notifications", path: "components/notifications"
gem "pickup_sports", path: "components/pickup_sports"
gem "platform_core", path: "components/platform_core"
gem "restaurants",   path: "components/restaurants"

group :development, :test do
  gem "factory_bot_rails"
  gem "rspec-rails", "~> 7.0"
  gem "rubocop-rails", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
