require "rails_helper"

RSpec.describe Restaurants::Elo do
  it "moves the winner up and the loser down" do
    new_winner, new_loser = described_class.updated_ratings(1500, 1500)
    expect(new_winner).to be > 1500
    expect(new_loser).to be < 1500
  end

  it "is zero-sum for equal ratings (K split evenly)" do
    new_winner, new_loser = described_class.updated_ratings(1500, 1500)
    expect(new_winner - 1500).to eq(1500 - new_loser)
  end

  it "rewards an upset more than an expected win" do
    upset_gain = described_class.updated_ratings(1400, 1600).first - 1400
    expected_gain = described_class.updated_ratings(1600, 1400).first - 1600
    expect(upset_gain).to be > expected_gain
  end
end
