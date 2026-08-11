require "rails_helper"
require "prop_check"
require "uri"

RSpec.describe "pure model properties" do
  def generators
    PropCheck::Generators
  end

  def check_property(*bindings, &)
    runs = Integer(ENV.fetch("PROP_CHECK_RUNS", "100"), 10)
    PropCheck.forall(*bindings).with_config(n_runs: runs, &)
  end

  describe Restaurants::Elo do
    it "conserves total rating and limits each result to one K-factor" do
      rating = generators.choose(100..3_000)

      check_property(rating, rating) do |winner_rating, loser_rating|
        winner, loser = described_class.updated_ratings(winner_rating, loser_rating)
        gain = winner - winner_rating

        expect(winner + loser).to eq(winner_rating + loser_rating)
        expect(gain).to be_between(0, described_class::K).inclusive
      end
    end

    it "is invariant when both ratings are translated equally" do
      rating = generators.choose(100..3_000)
      offset = generators.choose(-1_000..1_000)

      check_property(rating, rating, offset) do |winner_rating, loser_rating, shift|
        original = described_class.updated_ratings(winner_rating, loser_rating)
        translated = described_class.updated_ratings(winner_rating + shift, loser_rating + shift)

        expect(translated).to eq(original.map { |value| value + shift })
      end
    end
  end

  describe Events::Event do
    it "keeps fingerprints stable after text normalization and within a Chicago calendar day" do
      text = generators.printable_ascii_string(max: 32)
      date = generators.choose(Date.new(2024, 1, 1).jd..Date.new(2030, 12, 31).jd).map { Date.jd(_1) }
      minute = generators.choose(0...1_440)
      zone = ActiveSupport::TimeZone[described_class::TIME_ZONE]

      check_property(text, text, date, minute, minute) do |title, venue, local_date, first_minute, second_minute|
        normalized_title = described_class.normalize_text(title)
        normalized_venue = described_class.normalize_text(venue)
        first = zone.local(local_date.year, local_date.month, local_date.day, *first_minute.divmod(60))
        second = zone.local(local_date.year, local_date.month, local_date.day, *second_minute.divmod(60))

        expect(described_class.normalize_text(normalized_title)).to eq(normalized_title)
        expect(described_class.fingerprint_for(title, venue, first)).to(
          eq(described_class.fingerprint_for(normalized_title, normalized_venue, second))
        )
      end
    end

    it "normalizes calendar bounds to the same UTC interval in Google and ICS exports" do
      seconds = generators.choose(Time.utc(2024).to_i..Time.utc(2031).to_i)
      offset_quarters = generators.choose(-48..56)
      duration = generators.choose(1..(12 * 60 * 60))

      check_property(seconds, offset_quarters, duration, generators.boolean) do |epoch, quarters, length, explicit_end|
        starts_at = Time.at(epoch).getlocal(quarters * 15 * 60)
        ends_at = starts_at + length if explicit_end
        event = described_class.new(title: "Fuzz event", fingerprint: "fuzz", starts_at: starts_at, ends_at: ends_at)
        expected_start = starts_at.utc.strftime("%Y%m%dT%H%M%SZ")
        expected_end_time = ends_at || (starts_at + described_class::DEFAULT_DURATION)
        expected_end = expected_end_time.utc.strftime("%Y%m%dT%H%M%SZ")
        google_dates = URI.decode_www_form(URI(event.google_calendar_url).query).to_h.fetch("dates")
        ics = event.to_ics(now: starts_at)

        expect(google_dates).to eq("#{expected_start}/#{expected_end}")
        expect(ics).to include("DTSTART:#{expected_start}\r\n", "DTEND:#{expected_end}\r\n")
      end
    end
  end
end
