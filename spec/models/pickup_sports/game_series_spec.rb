require "rails_helper"

RSpec.describe PickupSports::GameSeries, type: :model do
  after { PlatformCore::EventBus.reset! }

  it "schedules bounded weekly games with an independent host roster for each occurrence" do
    host = create(:user)
    first_start = 2.days.from_now.change(hour: 18, min: 30)
    series = build(:pickup_sports_game_series, host: host, starts_at: first_start, occurrences_count: 4)

    expect(series.schedule).to be(true)
    expect(series.games.pluck(:series_position, :starts_at)).to eq(
      [
        [1, first_start],
        [2, first_start.advance(weeks: 1)],
        [3, first_start.advance(weeks: 2)],
        [4, first_start.advance(weeks: 3)]
      ]
    )
    expect(series.games).to all(
      have_attributes(
        title: series.title,
        sport: series.sport,
        neighborhood: series.neighborhood,
        venue: series.venue,
        capacity: series.capacity
      )
    )
    expect(series.games.map { |game| game.entry_for(host.id)&.status }).to eq(%w[joined joined joined joined])
  end

  it "rejects unsafe series lengths and past starts without creating games" do
    series = build(:pickup_sports_game_series, occurrences_count: 9, starts_at: 1.minute.ago)

    expect(series.schedule).to be(false)
    expect(series.errors).to include(:occurrences_count, :starts_at)
    expect(series).not_to be_persisted
    expect(PickupSports::Game.where(game_series_id: series.id)).to be_empty
  end

  it "publishes one primitive series event plus the existing event for each scheduled game" do
    published = []
    %w[pickup_sports.series_created pickup_sports.game_created].each do |event_name|
      PlatformCore::EventBus.subscribe(event_name, ->(name, payload) { published << [name, payload] })
    end
    series = build(:pickup_sports_game_series, occurrences_count: 2, details: "Gate code must stay private")

    series.schedule

    series_event = published.find { |name, _payload| name == "pickup_sports.series_created" }.last
    expect(series_event).to eq(
      series_id: series.id,
      host_id: series.host_id,
      game_ids: series.games.ids,
      target_path: "/pickup_sports/series/#{series.id}"
    )
    expect(published.count { |name, _payload| name == "pickup_sports.game_created" }).to eq(2)
    expect(published.to_s).not_to include("Gate code")
  end
end
