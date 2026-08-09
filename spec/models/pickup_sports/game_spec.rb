require "rails_helper"

RSpec.describe PickupSports::Game, type: :model do
  after { PlatformCore::EventBus.reset! }

  it "requires a future, bounded, well-described game and seats the host" do
    host = create(:user)
    game = create(:pickup_sports_game, host: host, capacity: 8)

    expect(game.roster_entries).to contain_exactly(
      have_attributes(resident_id: host.id, status: "joined")
    )
    expect(game.joined_count).to eq(1)

    invalid = build(:pickup_sports_game, starts_at: 1.minute.ago, capacity: 1, sport: "chess")
    expect(invalid).not_to be_valid
    expect(invalid.errors).to include(:starts_at, :capacity, :sport)
  end

  it "assigns the final spot once, waitlists later residents, and ignores duplicate joins" do
    game = create(:pickup_sports_game, capacity: 2)
    player = create(:user)
    waiting = create(:user)

    first_entry = game.join!(player.id)
    expect(first_entry).to be_joined
    expect(game.join!(player.id)).to eq(first_entry)

    waitlist_entry = game.join!(waiting.id)
    expect(waitlist_entry).to be_waitlisted
    expect(game.roster_entries.where(resident_id: player.id).count).to eq(1)
  end

  it "promotes the earliest waitlisted resident when a player leaves" do
    game = create(:pickup_sports_game, capacity: 2)
    player = create(:user)
    first_waiting = create(:user)
    second_waiting = create(:user)
    game.join!(player.id)
    first_entry = game.join!(first_waiting.id)
    second_entry = game.join!(second_waiting.id)
    first_entry.update_column(:created_at, 2.minutes.ago)
    second_entry.update_column(:created_at, 1.minute.ago)

    promoted = game.leave!(player.id)

    expect(promoted).to eq(first_entry)
    expect(first_entry.reload).to be_joined
    expect(second_entry.reload).to be_waitlisted
  end

  it "keeps the host committed and blocks new joins after cancellation" do
    game = create(:pickup_sports_game)
    game.cancel!

    expect { game.leave!(game.host_id) }.to raise_error(PickupSports::Game::ParticipationError, /Hosts stay/)
    expect { game.join!(create(:user).id) }.to raise_error(PickupSports::Game::ParticipationError, /no longer/)
  end

  it "publishes primitive, content-free game and promotion events" do
    published = []
    %w[pickup_sports.game_created pickup_sports.game_changed pickup_sports.roster_promoted].each do |event_name|
      PlatformCore::EventBus.subscribe(event_name, ->(name, payload) { published << [name, payload] })
    end

    game = create(:pickup_sports_game, capacity: 2, details: "Private door code should not leave the module")
    player = create(:user)
    waiting = create(:user)
    game.join!(player.id)
    game.join!(waiting.id)
    game.leave!(player.id)
    game.cancel!

    created = published.find { |name, _payload| name == "pickup_sports.game_created" }.last
    promoted = published.find { |name, _payload| name == "pickup_sports.roster_promoted" }.last
    changed = published.find { |name, _payload| name == "pickup_sports.game_changed" }.last

    expect(created).to eq(game_id: game.id, host_id: game.host_id, target_path: "/pickup_sports/games/#{game.id}")
    expect(promoted).to include(game_id: game.id, recipient_id: waiting.id, host_id: game.host_id)
    expect(changed).to include(game_id: game.id, actor_id: game.host_id, change_kind: "canceled")
    expect(published.to_s).not_to include("Private door code")
  end
end
