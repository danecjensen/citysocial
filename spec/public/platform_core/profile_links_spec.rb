require "rails_helper"

RSpec.describe PlatformCore::ProfileLinks do
  # The registry is process-global (modules register into it at boot), so snapshot
  # and restore it around each example rather than leaking spec-only links.
  around do |example|
    saved = described_class.registry.dup
    example.run
    described_class.registry.replace(saved)
  end

  it "registers a link and returns it in position order" do
    described_class.register(key: "spec_b", label: "Bravo", path: "/b", position: 20)
    described_class.register(key: "spec_a", label: "Alpha", path: "/a", position: 10)

    spec_links = described_class.all.select { |link| link.key.start_with?("spec_") }

    expect(spec_links.map(&:label)).to eq(%w[Alpha Bravo])
    expect(spec_links.first).to have_attributes(key: "spec_a", path: "/a")
  end

  it "hides a link whose module is switched off" do
    described_class.register(key: "spec_gated", label: "Gated", path: "/g", module_key: "messaging")

    PlatformCore::Modules.disable!("messaging")
    expect(described_class.all.map(&:key)).not_to include("spec_gated")

    PlatformCore::Modules.enable!("messaging")
    expect(described_class.all.map(&:key)).to include("spec_gated")
  ensure
    PlatformCore::Modules.enable!("messaging")
  end

  it "resolves the unread count lazily from the registered block" do
    described_class.register(key: "spec_count", label: "Counter", path: "/c") { |user_id| user_id * 2 }

    link = described_class.all.find { |candidate| candidate.key == "spec_count" }

    expect(link.unread_count(3)).to eq(6)
  end

  it "reports zero unread for a link registered without a counter block" do
    described_class.register(key: "spec_plain", label: "Plain", path: "/p")

    link = described_class.all.find { |candidate| candidate.key == "spec_plain" }

    expect(link.unread_count(99)).to eq(0)
  end
end
