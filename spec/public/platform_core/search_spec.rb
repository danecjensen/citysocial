require "rails_helper"

RSpec.describe PlatformCore::Search do
  def result(title: "Found", path: "/found", type: "spec_result")
    described_class::Result.new(title: title, subtitle: "Nearby", path: path, type: type)
  end

  def register(key, type: "spec_result", module_key: "platform_core", callable: nil)
    described_class.register(
      key: key,
      label: key.titleize,
      module_key: module_key,
      types: [type],
      callable: callable || ->(query:, limit:) { [result(title: "#{query}-#{limit}", type: type)] }
    )
  end

  after do
    %w[spec-replace spec-clamp spec-good spec-bad spec-invalid spec-disabled].each do |key|
      described_class.unregister(key)
    end
  end

  it "replaces providers by key so reload registration is idempotent" do
    register("spec-replace", callable: ->(**) { [result(title: "Old")] })
    register("spec-replace", callable: ->(**) { [result(title: "New")] })

    response = described_class.call(query: "anything", type: "spec_result")
    group = response.groups.find { |candidate| candidate.key == "spec-replace" }

    expect(group.results.map(&:title)).to eq(["New"])
    expect(response.groups.count { |candidate| candidate.key == "spec-replace" }).to eq(1)
  end

  it "clamps query length and result limits before invoking a provider" do
    received = nil
    register(
      "spec-clamp",
      type: "spec_clamp",
      callable: lambda do |query:, limit:|
        received = [query, limit]
        Array.new(20) { |index| result(title: "Result #{index}", type: "spec_clamp") }
      end
    )

    response = described_class.call(query: "x" * 150, type: "spec_clamp", limit: 50)

    expect(received).to eq(["x" * described_class::MAX_QUERY_LENGTH, described_class::MAX_LIMIT])
    expect(response.groups.first.results.length).to eq(described_class::MAX_LIMIT)
  end

  it "isolates provider failures and preserves successful groups" do
    register("spec-good", callable: ->(**) { [result(title: "Still visible")] })
    register("spec-bad", callable: ->(**) { raise "private provider failure" })

    response = described_class.call(query: "city", type: "spec_result")

    expect(response.groups.find { |group| group.key == "spec-good" }.results.first.title).to eq("Still visible")
    failed = response.groups.find { |group| group.key == "spec-bad" }
    expect(failed).to be_unavailable
    expect(failed.results).to be_empty
  end

  it "rejects non-canonical result paths without exposing the bad result" do
    register("spec-invalid", callable: ->(**) { [result(path: "https://example.com/leak")] })

    group = described_class.call(query: "city", type: "spec_result").groups.first

    expect(group).to be_unavailable
    expect(group.results).to be_empty
  end

  it "checks module enablement at query time and never invokes disabled providers" do
    callable = instance_spy(Proc)
    register("spec-disabled", type: "spec_disabled", module_key: "marketplace", callable: callable)
    allow(PlatformCore::Modules).to receive(:enabled?).with("marketplace").and_return(false)

    group = described_class.call(query: "city", type: "spec_disabled").groups.first

    expect(group).to be_disabled
    expect(callable).not_to have_received(:call)
  end
end
