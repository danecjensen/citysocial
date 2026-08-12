require "rails_helper"

RSpec.describe PlatformCore::ProfilePanels do
  # The registry is process-global (modules register into it at boot), so snapshot
  # and restore it around each example rather than leaking spec-only panels.
  around do |example|
    saved = described_class.registry.dup
    example.run
    described_class.registry.replace(saved)
  end

  it "registers a panel and returns it in position order" do
    described_class.register(key: "spec_b", position: 20) { |_user| :b }
    described_class.register(key: "spec_a", position: 10) { |_user| :a }

    spec = described_class.all.select { |panel| panel.key.start_with?("spec_") }

    expect(spec.map(&:key)).to eq(%w[spec_a spec_b])
  end

  it "builds the panel component lazily with the profile owner" do
    user = create(:user)
    described_class.register(key: "spec_panel") { |owner| "panel-for-#{owner.id}" }

    panel = described_class.all.find { |candidate| candidate.key == "spec_panel" }

    expect(panel.component(user)).to eq("panel-for-#{user.id}")
  end

  it "hides a panel whose module is switched off" do
    described_class.register(key: "spec_gated", module_key: "messaging") { |_user| :x }

    PlatformCore::Modules.disable!("messaging")
    expect(described_class.all.map(&:key)).not_to include("spec_gated")

    PlatformCore::Modules.enable!("messaging")
    expect(described_class.all.map(&:key)).to include("spec_gated")
  ensure
    PlatformCore::Modules.enable!("messaging")
  end

  it "refuses a registration without a component block" do
    expect { described_class.register(key: "spec_bad") }.to raise_error(ArgumentError)
  end
end
