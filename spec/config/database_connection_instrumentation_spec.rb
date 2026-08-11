require "rails_helper"

RSpec.describe DatabaseConnectionInstrumentation do
  subject(:pool) do
    Class.new do
      prepend DatabaseConnectionInstrumentation

      def checkout(*)
        :connection
      end

      def new_connection
        :new_connection
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

  it "does not log healthy connection checkouts" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_010.0)

    pool.checkout

    expect(logger).not_to have_received(:warn)
  end

  it "logs slow physical connection creation separately" do
    allow(pool).to receive(:monotonic_milliseconds).and_return(1_000.0, 1_300.0)

    expect(pool.send(:new_connection)).to eq(:new_connection)
    expect(logger).to have_received(:warn).with(
      "event=database_connection_connect duration_ms=300.0 threshold_ms=250.0 " \
      "status=slow pool=primary size=5 connections=5 busy=4 idle=1 waiting=2"
    )
  end
end
