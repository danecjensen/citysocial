require "rails_helper"

RSpec.describe Notifications::Inbox do
  it "counts only the resident's unread notifications" do
    resident = create(:user)
    create(:notification, recipient: resident)
    create(:notification, recipient: resident, read_at: Time.current)
    create(:notification)

    expect(described_class.unread_count_for(resident.id)).to eq(1)
  end
end
