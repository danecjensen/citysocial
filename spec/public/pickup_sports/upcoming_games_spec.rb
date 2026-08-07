require "rails_helper"

RSpec.describe PickupSports::UpcomingGames do
  it "returns bounded, read-only summaries for upcoming open games" do
    open_game = create(:pickup_sports_game, title: "Open soccer", capacity: 2)
    open_game.join!(create(:user).id)
    open_game.join!(create(:user).id)
    canceled = create(:pickup_sports_game, title: "Canceled tennis")
    canceled.cancel!
    past = create(:pickup_sports_game, title: "Yesterday volleyball")
    past.update_columns(starts_at: 1.day.ago)

    summaries = described_class.call(limit: 1)

    expect(summaries).to contain_exactly(
      have_attributes(
        id: open_game.id,
        title: "Open soccer",
        capacity: 2,
        joined_count: 2,
        waitlisted_count: 1,
        host_id: open_game.host_id
      )
    )
    expect(summaries.map(&:id)).not_to include(canceled.id, past.id)
  end
end
