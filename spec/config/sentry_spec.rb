require "rails_helper"

RSpec.describe "Sentry configuration" do
  subject(:configuration) { Sentry.configuration }

  it "uses production-only, privacy-preserving defaults" do
    expect(configuration.enabled_environments).to eq(["production"])
    expect(configuration.send_default_pii).to be(false)
    expect(configuration.include_local_variables).to be(false)
    expect(configuration.strict_trace_continuation).to be(true)
    expect(configuration.trace_propagation_targets).to be_empty
  end

  it "captures structured operational signals without duplicating SQL as logs" do
    expect(configuration.enable_logs).to be(true)
    expect(configuration.enable_metrics).to be(true)
    expect(configuration.rails.structured_logging.subscribers.keys).to contain_exactly(
      :action_controller,
      :active_job,
      :action_mailer
    )
    expect(configuration.profiler_class).to eq(Sentry::Vernier::Profiler)
  end

  it "samples APIs and jobs deliberately while honoring parent decisions" do
    sampler = configuration.traces_sampler

    expect(sampler.call(parent_sampled: true, transaction_context: {}, env: {})).to be(true)
    expect(sampler.call(parent_sampled: false, transaction_context: {}, env: {})).to be(false)
    expect(sampler.call(parent_sampled: nil, transaction_context: {}, env: { "PATH_INFO" => "/health" })).to eq(0.0)
    api_context = { parent_sampled: nil, transaction_context: {}, env: { "PATH_INFO" => "/api/v1/posts" } }
    expect(sampler.call(api_context)).to eq(0.25)
    expect(sampler.call(parent_sampled: nil, transaction_context: { op: "queue.process" }, env: {})).to eq(0.05)
    expect(sampler.call(parent_sampled: nil, transaction_context: {}, env: { "PATH_INFO" => "/feed" })).to eq(0.1)
  end

  it "removes Sidekiq arguments from error and performance events" do
    event = Sentry::Event.new(configuration: configuration)
    event.contexts = { sidekiq: { "queue" => "default", "args" => ["private resident text"] } }

    expect(configuration.before_send.call(event).contexts.dig(:sidekiq, "args")).to eq("[Filtered]")
    expect(event.contexts.dig(:sidekiq, "queue")).to eq("default")
  end

  it "filters credentials and resident-authored text from Rails instrumentation" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      password: "secret",
      email: "resident@example.com",
      body: "private message",
      description: "private details",
      title: "Public title"
    )

    expect(filtered).to include(
      password: "[FILTERED]",
      email: "[FILTERED]",
      body: "[FILTERED]",
      description: "[FILTERED]",
      title: "Public title"
    )
  end
end
