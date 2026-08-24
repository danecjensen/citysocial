require "rails_helper"

RSpec.describe PlatformCore::EventBus do
  # Subscribe test-only handlers to unique event names so we never disturb the
  # real module wiring registered at boot.
  def unique_event
    "test.event_bus_#{SecureRandom.hex(4)}"
  end

  it "delivers an event to an inline subscriber" do
    seen = []
    event = unique_event
    described_class.subscribe(event, ->(name, payload) { seen << [name, payload] })

    described_class.publish(event, id: 1)

    expect(seen).to eq([[event, { id: 1 }]])
  end

  it "enqueues an async subscriber instead of running it inline" do
    event = unique_event
    handler = Class.new do
      def self.call(*)
        raise "must not run inline"
      end
    end
    described_class.subscribe(event, handler, async: true)
    allow(PlatformCore::EventBus::AsyncDispatch).to receive(:perform_later)

    described_class.publish(event, id: 7)

    expect(PlatformCore::EventBus::AsyncDispatch).to have_received(:perform_later)
      .with(event, handler.to_s, { id: 7 })
  end

  it "isolates a raising inline subscriber so the publisher and siblings still succeed" do
    ran = []
    event = unique_event
    described_class.subscribe(event, ->(_name, _payload) { raise "subscriber boom" })
    described_class.subscribe(event, ->(_name, _payload) { ran << :sibling })
    allow(Rails.logger).to receive(:error)

    expect { described_class.publish(event, id: 1) }.not_to raise_error
    expect(ran).to eq([:sibling])
    expect(Rails.logger).to have_received(:error).with(/event_bus_delivery_failed.*subscriber boom/m)
  end

  it "does not let an unreachable job backend at enqueue time break the publisher" do
    event = unique_event
    handler = Class.new do
      def self.call(*)
        nil
      end
    end
    described_class.subscribe(event, handler, async: true)
    allow(PlatformCore::EventBus::AsyncDispatch).to receive(:perform_later)
      .and_raise("simulated Redis outage at enqueue")
    allow(Rails.logger).to receive(:error)

    expect { described_class.publish(event, id: 1) }.not_to raise_error
    expect(Rails.logger).to have_received(:error).with(/event_bus_delivery_failed.*async=true/m)
  end
end
