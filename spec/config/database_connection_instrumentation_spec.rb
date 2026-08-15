require "rails_helper"

RSpec.describe DatabaseConnectionInstrumentation do
  let(:physical_connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter, connect!: true) }

  subject(:pool) do
    connection = physical_connection
    Class.new do
      prepend DatabaseConnectionInstrumentation

      define_method(:physical_connection) { connection }

      def checkout(*)
        :connection
      end

      def new_connection
        physical_connection
      end

      def stat
        { size: 5, connections: 5, busy: 4, idle: 1, waiting: 2 }
      end

      def db_config
        Struct.new(:name).new("primary")
      end
    end.new
  end

  let(:logger) { instance_spy(ActiveSupport::Logger) }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
  end

  it "is installed on Active Record connection pools" do
    expect(ActiveRecord::ConnectionAdapters::ConnectionPool.ancestors).to include(described_class)
  end

  it "logs slow connection checkouts with pool pressure context" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_150.5)

    expect(pool.checkout).to eq(:connection)
    expect(logger).to have_received(:warn).with(
      "event=database_connection_checkout duration_ms=150.5 threshold_ms=100.0 " \
      "status=slow pool=primary size=5 connections=5 busy=4 idle=1 waiting=2"
    )
  end

  it "sends slow connection logs and trace-connected metrics to Sentry when enabled" do
    sentry_config = instance_double(Sentry::Configuration, sending_allowed?: true, enable_logs: true)
    metrics = spy("Sentry metrics")
    sentry_logger = spy("Sentry logger")
    allow(Sentry).to receive_messages(
      initialized?: true,
      configuration: sentry_config,
      metrics: metrics,
      logger: sentry_logger
    )
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_150.5)

    pool.checkout

    expect(metrics).to have_received(:distribution).with(
      "citysocial.database_connection.duration",
      150.5,
      unit: "millisecond",
      attributes: { operation: "checkout", status: "slow", pool: "primary" }
    )
    expect(sentry_logger).to have_received(:warn).with(
      "Database connection slow or failed",
      hash_including(operation: "checkout", status: "slow", duration_ms: 150.5, origin: "manual.database")
    )
  end

  it "does not log healthy connection checkouts" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_010.0)

    pool.checkout

    expect(logger).not_to have_received(:warn)
  end

  it "logs slow physical connection creation separately" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_300.0)

    expect(pool.send(:new_connection)).to eq(physical_connection)
    expect(physical_connection).to have_received(:connect!)
    expect(logger).to have_received(:warn).with(
      "event=database_connection_connect duration_ms=300.0 threshold_ms=250.0 " \
      "status=slow pool=primary size=5 connections=5 busy=4 idle=1 waiting=2"
    )
  end

  it "eagerly establishes healthy physical connections without logging them" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_010.0)

    expect(pool.send(:new_connection)).to eq(physical_connection)
    expect(physical_connection).to have_received(:connect!)
    expect(logger).not_to have_received(:warn)
  end
end
