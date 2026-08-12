require "rails_helper"

RSpec.describe Restaurants::RecordMatchup do
  let(:winner) { create(:restaurant) }
  let(:loser) { create(:restaurant) }
  let(:voter) { create(:user) }

  def record_matchup
    described_class.call(winner_id: winner.id, loser_id: loser.id, voter_id: voter.id)
  end

  it "updates both Elo ratings and counts the matchup" do
    record_matchup

    expect(winner.reload.elo).to be > 1500
    expect(loser.reload.elo).to be < 1500
    expect(winner.matches_count).to eq(1)
    expect(loser.matches_count).to eq(1)
  end

  it "uses the canonical Elo calculation" do
    winner.update_columns(elo: 1687)
    loser.update_columns(elo: 1423)
    expected_winner_elo, expected_loser_elo = Restaurants::Elo.updated_ratings(winner.elo, loser.elo)

    record_matchup

    expect(winner.reload.elo).to eq(expected_winner_elo)
    expect(loser.reload.elo).to eq(expected_loser_elo)
  end

  it "records a vote" do
    expect do
      record_matchup
    end.to change(Restaurants::Vote, :count).by(1)
  end

  it "returns the recorded decision and winner name" do
    result = record_matchup

    expect(result).to have_attributes(
      voter_id: voter.id,
      winner_id: winner.id,
      loser_id: loser.id,
      winner_name: winner.name
    )
    expect(result.vote_id).to eq(Restaurants::Vote.last.id)
  end

  it "performs the rating updates and vote insert in one database round trip" do
    winner
    loser
    voter
    queries = []
    subscriber = lambda do |_name, _started, _finished, _id, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached]
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { record_matchup }

    expect(queries.size).to eq(1)
    expect(queries.first).to include("updated_restaurants", "inserted_vote")
  end

  it "does not change anything when either restaurant is missing" do
    original_vote_count = Restaurants::Vote.count

    expect do
      described_class.call(winner_id: winner.id, loser_id: -1, voter_id: voter.id)
    end.to raise_error(ActiveRecord::RecordNotFound)

    expect(Restaurants::Vote.count).to eq(original_vote_count)
    expect(winner.reload).to have_attributes(elo: 1500, matches_count: 0)
  end

  it "rejects a matchup against the same restaurant" do
    original_vote_count = Restaurants::Vote.count

    expect do
      described_class.call(winner_id: winner.id, loser_id: winner.id, voter_id: voter.id)
    end.to raise_error(ArgumentError, "a restaurant cannot beat itself")

    expect(Restaurants::Vote.count).to eq(original_vote_count)
    expect(winner.reload).to have_attributes(elo: 1500, matches_count: 0)
  end

  it "publishes restaurants.matchup_decided" do
    published = []
    PlatformCore::EventBus.subscribe(
      "restaurants.matchup_decided",
      ->(_name, payload) { published << payload }
    )

    record_matchup

    expect(published.size).to eq(1)
    expect(published.first).to include(winner_id: winner.id, loser_id: loser.id, voter_id: voter.id)
  ensure
    PlatformCore::EventBus.reset!
  end
end
