require "rails_helper"

# Guards the test-environment queue adapter. The app uses Sidekiq in real
# environments, but the test suite must not depend on a running Redis: with the
# Sidekiq adapter, any job enqueued during a spec (e.g. Active Storage's
# AnalyzeJob when a photo is attached) raises RedisClient::CannotConnectError.
# Keeping the :test adapter enqueues jobs into an in-memory array instead.
RSpec.describe "test environment ActiveJob adapter" do
  it "uses the in-memory :test adapter, never Sidekiq/Redis" do
    expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::TestAdapter)
  end
end
