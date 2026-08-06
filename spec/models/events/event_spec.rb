require "rails_helper"

RSpec.describe Events::Event, type: :model do
  describe "deterministic fingerprint" do
    it "is stable for the same title, venue, and calendar day regardless of time or casing" do
      a = Events::Event.fingerprint_for("La Bohème", "The Long Center", "2026-08-08T19:30:00-05:00")
      b = Events::Event.fingerprint_for("  la  bohème ", "the long center", "2026-08-08T21:00:00-05:00")

      expect(a).to eq(b)
    end

    it "differs across calendar days and across venues" do
      base = Events::Event.fingerprint_for("Dr. Dog", "Mohawk", "2026-08-08T20:00:00-05:00")
      other_day = Events::Event.fingerprint_for("Dr. Dog", "Mohawk", "2026-08-09T20:00:00-05:00")
      other_venue = Events::Event.fingerprint_for("Dr. Dog", "Hotel Vegas", "2026-08-08T20:00:00-05:00")

      expect(base).not_to eq(other_day)
      expect(base).not_to eq(other_venue)
    end

    it "rejects a second event that collapses onto the same fingerprint" do
      start = Time.zone.parse("2026-08-08T20:00:00-05:00")
      create(:event, title: "Sun June", venue: "Mohawk", starts_at: start)
      dup = build(:event, title: "sun june", venue: "MOHAWK", starts_at: start + 1.hour)

      expect(dup).not_to be_valid
      expect(dup.errors[:fingerprint]).to be_present
    end
  end

  describe "category" do
    it "clamps unknown categories to 'other'" do
      event = create(:event, category: "networking-mixer")
      expect(event.category).to eq("other")
    end
  end

  describe ".weekly_top" do
    it "returns the highest-scoring events within the next 7 days, best first" do
      in_window_hi = create(:event, title: "Headliner", score: 0.95, starts_at: 2.days.from_now)
      in_window_lo = create(:event, title: "Undercard", score: 0.10, starts_at: 3.days.from_now)
      create(:event, title: "Way Out", score: 0.99, starts_at: 30.days.from_now)
      create(:event, title: "Yesterday", score: 0.99, starts_at: 1.day.ago)

      top = Events::Event.weekly_top(10)

      expect(top).to eq([in_window_hi, in_window_lo])
    end

    it "honors the limit" do
      12.times { |i| create(:event, score: i / 10.0, starts_at: 2.days.from_now) }
      expect(Events::Event.weekly_top(10).size).to eq(10)
    end
  end

  describe ".search" do
    it "matches title, venue, and description case-insensitively" do
      match = create(:event, title: "Vintage Film Night", venue: "Alamo Drafthouse")
      create(:event, title: "Startup Talk", venue: "Capital Factory")

      expect(Events::Event.search("alamo")).to contain_exactly(match)
      expect(Events::Event.search("VINTAGE")).to contain_exactly(match)
    end
  end

  describe "calendar export" do
    let(:start) { Time.zone.parse("2026-08-08T20:00:00-05:00") }

    describe "#calendar_ends_at" do
      it "uses the event's own end time when present" do
        finish = start + 3.hours
        event = build(:event, starts_at: start, ends_at: finish)
        expect(event.calendar_ends_at).to eq(finish)
      end

      it "falls back to a defined duration after the start when ends_at is blank" do
        event = build(:event, starts_at: start, ends_at: nil)
        expect(event.calendar_ends_at).to eq(start + Events::Event::DEFAULT_DURATION)
      end
    end

    describe "#google_calendar_url" do
      it "builds a template link with UTC start/end, title, location, and details" do
        event = build(
          :event,
          title: "Sun June",
          venue: "Mohawk",
          description: "Dream pop",
          url: "https://mohawkaustin.com/sun-june",
          starts_at: start,
          ends_at: nil
        )

        url = event.google_calendar_url

        expect(url).to start_with("https://calendar.google.com/calendar/render?")
        expect(url).to include("action=TEMPLATE")
        expect(url).to include("text=Sun+June")
        expect(url).to include("dates=20260809T010000Z%2F20260809T030000Z")
        expect(url).to include("location=Mohawk")
        expect(url).to include(CGI.escape("https://mohawkaustin.com/sun-june"))
      end
    end

    describe "#to_ics" do
      it "produces a valid VCALENDAR with escaped text and CRLF lines" do
        event = build(
          :event,
          title: "Jazz, Blues; & More",
          venue: "The Elephant Room",
          description: "Line one\nLine two",
          url: "https://example.com/jazz",
          starts_at: start,
          ends_at: start + 90.minutes
        )
        now = Time.zone.parse("2026-08-01T12:00:00-05:00")

        ics = event.to_ics(now: now)

        expect(ics).to start_with("BEGIN:VCALENDAR\r\n")
        expect(ics).to end_with("END:VCALENDAR\r\n")
        expect(ics).to include("VERSION:2.0")
        expect(ics).to include("BEGIN:VEVENT").and include("END:VEVENT")
        expect(ics).to include("DTSTAMP:20260801T170000Z")
        expect(ics).to include("DTSTART:20260809T010000Z")
        expect(ics).to include("DTEND:20260809T023000Z")
        expect(ics).to include("SUMMARY:Jazz\\, Blues\\; & More")
        expect(ics).to include("DESCRIPTION:Line one\\nLine two")
        expect(ics).to include("LOCATION:The Elephant Room")
        expect(ics).to include("URL:https://example.com/jazz")
      end

      it "uses the fallback end time in the ICS when ends_at is blank" do
        event = build(:event, starts_at: start, ends_at: nil)
        expect(event.to_ics).to include("DTEND:20260809T030000Z")
      end
    end
  end
end
