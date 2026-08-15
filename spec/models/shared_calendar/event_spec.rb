require "rails_helper"

RSpec.describe SharedCalendar::Event, type: :model do
  it "accepts a clear time range and exposes category presentation" do
    event = build(:shared_calendar_event, category: "music")

    expect(event).to be_valid
    expect(event.category_label).to eq("Music")
    expect(event.category_symbol).to eq("♫")
  end

  it "requires the end to follow the start" do
    event = build(:shared_calendar_event, ends_at: 1.day.ago)

    expect(event).not_to be_valid
    expect(event.errors[:ends_at]).to include("must be after the start time")
  end

  it "accepts displayable images and rejects unsupported attachments" do
    event = build(:shared_calendar_event, :with_image)
    expect(event).to be_valid

    event.image.attach(io: StringIO.new("document"), filename: "schedule.pdf", content_type: "application/pdf")
    expect(event).not_to be_valid
    expect(event.errors[:image]).to include("must be a JPEG, PNG, or WebP image")
  end

  it "announces new events without publishing their content" do
    allow(PlatformCore::EventBus).to receive(:publish)

    event = create(:shared_calendar_event)

    expect(PlatformCore::EventBus).to have_received(:publish).with(
      "shared_calendar.event_created",
      event_id: event.id,
      author_id: event.author_id,
      target_path: "/shared_calendar/#{event.id}",
      media_blob_ids: [],
      media_count: 0
    )
  end
end
