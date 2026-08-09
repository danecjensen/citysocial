require "rails_helper"

RSpec.describe NeighborHelp::Events do
  after { PlatformCore::EventBus.reset! }

  it "publishes creation and lifecycle events with primitive, content-free payloads" do
    published = []
    %w[neighbor_help.request_created neighbor_help.request_changed].each do |event_name|
      PlatformCore::EventBus.subscribe(event_name, ->(name, payload) { published << [name, payload] })
    end

    requester = create(:user)
    helper = create(:user)
    request = create(
      :neighbor_help_request,
      requester: requester,
      details: "Private coordination should never leave this module."
    )
    request.claim!(helper.id)
    request.release!(helper.id)

    created = published.find { |name, _payload| name == "neighbor_help.request_created" }.last
    changed = published.filter_map do |name, payload|
      payload if name == "neighbor_help.request_changed"
    end

    expect(created).to eq(
      request_id: request.id,
      actor_id: requester.id,
      requester_id: requester.id,
      target_path: "/neighbor_help/requests/#{request.id}"
    )
    expect(changed.pluck(:change_kind)).to eq(%w[claimed released])
    expect(changed.first).to include(helper_id: helper.id, recipient_id: requester.id, status: "claimed")
    expect(published.to_s).not_to include("Private coordination")
  end
end
