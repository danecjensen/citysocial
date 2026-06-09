require "rails_helper"

RSpec.describe Restaurants::RecordMatchup do
  let(:winner) { create(:restaurant) }
  let(:loser) { create(:restaurant) }
  let(:voter) { create(:user) }

  it "updates both Elo ratings and counts the matchup" do
    described_class.call(winner: winner, loser: loser, voter_id: voter.id)

    expect(winner.reload.elo).to be > 1500
    expect(loser.reload.elo).to be < 1500
    expect(winner.matches_count).to eq(1)
    expect(loser.matches_count).to eq(1)
  end

  it "records a vote" do
    expect do
      described_class.call(winner: winner, loser: loser, voter_id: voter.id)
    end.to change(Restaurants::Vote, :count).by(1)
  end

  it "publishes restaurants.matchup_decided" do
    published = []
    PlatformCore::EventBus.subscribe(
      "restaurants.matchup_decided",
      ->(_name, payload) { published << payload }
    )

    described_class.call(winner: winner, loser: loser, voter_id: voter.id)

    expect(published.size).to eq(1)
    expect(published.first).to include(winner_id: winner.id, loser_id: loser.id, voter_id: voter.id)
  ensure
    PlatformCore::EventBus.reset!
  end
end
