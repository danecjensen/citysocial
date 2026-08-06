require "rails_helper"

RSpec.describe Notifications::Notification, type: :model do
  it "accepts only supported activity and internal target paths" do
    notification = build(:notification, event_name: "unknown.event", target_path: "https://example.com")

    expect(notification).not_to be_valid
    expect(notification.errors[:event_name]).to be_present
    expect(notification.errors[:target_path]).to include("must be an internal path")
  end

  it "marks an unread notification as read" do
    notification = create(:notification)

    expect { notification.mark_read! }.to change(notification, :unread?).from(true).to(false)
  end
end
