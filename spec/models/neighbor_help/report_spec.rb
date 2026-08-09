require "rails_helper"

RSpec.describe NeighborHelp::Report, type: :model do
  after { PlatformCore::EventBus.reset! }

  it "allows one report per resident and flags the request for review" do
    request = create(:neighbor_help_request)
    reporter = create(:user)

    report = create(:neighbor_help_report, request: request, reporter_id: reporter.id)

    expect(report.status).to eq("pending")
    expect(request.reload.moderation_state).to eq("reported")
    expect(build(:neighbor_help_report, request: request, reporter_id: reporter.id)).not_to be_valid
  end

  it "prevents a requester from reporting their own favor" do
    request = create(:neighbor_help_request)
    report = build(:neighbor_help_report, request: request, reporter_id: request.requester_id)

    expect(report).not_to be_valid
    expect(report.errors[:reporter_id]).to include("cannot report their own request")
  end
end
