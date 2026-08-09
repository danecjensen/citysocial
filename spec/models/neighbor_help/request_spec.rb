require "rails_helper"

RSpec.describe NeighborHelp::Request, type: :model do
  after { PlatformCore::EventBus.reset! }

  it "accepts a bounded unpaid favor and rejects contact, address, hazardous, or unconfirmed scope" do
    expect(build(:neighbor_help_request)).to be_valid

    unsafe = build(
      :neighbor_help_request,
      details: "Text 512-555-0199 and meet at 123 Main Street for paid electrical work.",
      no_cash_confirmed: false
    )

    expect(unsafe).not_to be_valid
    expect(unsafe.errors).to include(:base, :no_cash_confirmed)
    expect(unsafe.errors.full_messages.join(" ")).to include("phone number", "exact street address", "hazardous work")
  end

  it "requires a future, short time window and a bounded estimate" do
    request = build(
      :neighbor_help_request,
      starts_at: 1.hour.ago,
      ends_at: 8.days.from_now,
      estimated_minutes: 500
    )

    expect(request).not_to be_valid
    expect(request.errors).to include(:starts_at, :ends_at, :estimated_minutes)
  end

  it "atomically gives one neighbor the claim and lets only that helper release it" do
    request = create(:neighbor_help_request)
    first_helper = create(:user)
    other_helper = create(:user)

    expect(request.claim!(first_helper.id)).to be_claimed
    expect { request.claim!(other_helper.id) }.to raise_error(described_class::TransitionError, /no longer available/)
    expect { request.release!(other_helper.id) }.to raise_error(described_class::TransitionError, /current helper/)

    request.release!(first_helper.id)
    expect(request).to have_attributes(status: "open", helper_id: nil)
    expect(request.claim!(other_helper.id)).to have_attributes(status: "claimed", helper_id: other_helper.id)
  end

  it "lets the requester complete or cancel while blocking other residents" do
    requester = create(:user)
    helper = create(:user)
    request = create(:neighbor_help_request, requester: requester)
    request.claim!(helper.id)

    expect { request.complete!(helper.id) }.to raise_error(described_class::TransitionError, /Only the requester/)
    request.complete!(requester.id)
    expect(request).to be_completed

    cancelable = create(:neighbor_help_request, requester: requester)
    expect { cancelable.cancel!(helper.id) }.to raise_error(described_class::TransitionError, /Only the requester/)
    cancelable.cancel!(requester.id)
    expect(cancelable).to be_canceled
  end

  it "derives expiry without a destructive background rewrite" do
    request = create(:neighbor_help_request)
    request.update_columns(starts_at: 2.hours.ago, ends_at: 1.hour.ago)

    expect(request.reload).to be_expired
    expect(request.display_status).to eq("expired")
    expect(described_class.current).not_to include(request)
    expect { request.claim!(create(:user).id) }.to raise_error(described_class::TransitionError, /no longer available/)
  end
end
