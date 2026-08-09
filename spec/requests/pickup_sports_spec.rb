require "rails_helper"

RSpec.describe "Pickup Sports", type: :request do
  let(:host) { create(:user, handle: "host", display_name: "Court Host") }
  let(:player) { create(:user, handle: "player", display_name: "Ready Player") }

  after { PlatformCore::EventBus.reset! }

  it "lets anyone browse and filter upcoming games with a useful empty state" do
    matching = create(:pickup_sports_game, host: host, title: "East side soccer", sport: "soccer")
    create(:pickup_sports_game, title: "North tennis", sport: "tennis", neighborhood: "North Loop")

    get "/pickup_sports", params: { sport: "soccer", neighborhood: "east" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.title, "1/12 playing")
    expect(response.body).not_to include("North tennis")

    get "/pickup_sports", params: { sport: "basketball" }
    expect(response.body).to include("No matching games yet")
  end

  it "requires login to host and renders validation errors without creating a game" do
    get "/pickup_sports/games/new"
    expect(response).to redirect_to("/login")

    sign_in(host)
    post "/pickup_sports/games", params: {
      game: {
        title: "",
        sport: "soccer",
        skill_level: "all_levels",
        starts_at: 1.hour.ago,
        neighborhood: "East Austin",
        venue: "Pan Am Park",
        capacity: 1
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Title can&#39;t be blank", "Starts at must be in the future")
    expect(PickupSports::Game.count).to eq(0)
  end

  it "creates a complete host-owned game and prevents another resident from editing it" do
    sign_in(host)
    post "/pickup_sports/games", params: {
      game: {
        title: "Newcomer volleyball",
        sport: "volleyball",
        skill_level: "beginner",
        starts_at: 3.days.from_now.strftime("%Y-%m-%d %H:%M"),
        neighborhood: "Mueller",
        venue: "Branch Park",
        details: "We have a ball.",
        capacity: 10
      }
    }

    game = PickupSports::Game.last
    expect(response).to redirect_to("/pickup_sports/games/#{game.id}")
    expect(game).to have_attributes(host_id: host.id, title: "Newcomer volleyball", capacity: 10)
    expect(game.entry_for(host.id)).to be_joined

    sign_in(player)
    patch "/pickup_sports/games/#{game.id}", params: { game: { title: "Taken over" } }
    expect(response).to redirect_to("/pickup_sports/games/#{game.id}")
    expect(game.reload.title).to eq("Newcomer volleyball")
  end

  it "shows roster state, waitlists overflow, and promotes the earliest resident after a leave" do
    game = create(:pickup_sports_game, host: host, capacity: 2)
    waiting = create(:user, handle: "waiting", display_name: "Waiting Neighbor")

    sign_in(player)
    post "/pickup_sports/games/#{game.id}/roster_entry"
    expect(game.entry_for(player.id)).to be_joined

    sign_in(waiting)
    post "/pickup_sports/games/#{game.id}/roster_entry"
    expect(game.entry_for(waiting.id)).to be_waitlisted

    get "/pickup_sports/games/#{game.id}"
    expect(response.body).to include("You&#39;re on the waitlist", "Waiting Neighbor", "Wait 1")

    sign_in(player)
    delete "/pickup_sports/games/#{game.id}/roster_entry"
    expect(response).to redirect_to("/pickup_sports/games/#{game.id}")
    expect(game.entry_for(waiting.id).reload).to be_joined
  end

  it "lets only the host cancel and preserves a clear public canceled state" do
    game = create(:pickup_sports_game, host: host)
    sign_in(player)
    patch "/pickup_sports/games/#{game.id}/cancel"
    expect(game.reload).to be_open

    sign_in(host)
    patch "/pickup_sports/games/#{game.id}/cancel"
    expect(game.reload).to be_canceled

    get "/pickup_sports/games/#{game.id}"
    expect(response.body).to include("This game was canceled", "The roster remains visible")
    expect(response.body).not_to include("Join game")
  end

  it "lets only the host close attendance after the game and correct the public record" do
    game = create(:pickup_sports_game, host: host, capacity: 3)
    player_entry = game.join!(player.id)
    host_entry = game.entry_for(host.id)
    game.update_column(:starts_at, 1.hour.ago)

    sign_in(player)
    patch "/pickup_sports/games/#{game.id}/roster_entries/#{host_entry.id}/attendance",
          params: { attendance_status: "attended" }
    expect(response).to redirect_to("/pickup_sports/games/#{game.id}")
    expect(host_entry.reload).to be_joined

    sign_in(host)
    patch "/pickup_sports/games/#{game.id}/roster_entries/#{host_entry.id}/attendance",
          params: { attendance_status: "attended" }
    patch "/pickup_sports/games/#{game.id}/roster_entries/#{player_entry.id}/attendance",
          params: { attendance_status: "absent" }
    patch "/pickup_sports/games/#{game.id}/close_attendance"

    expect(game.reload).to be_completed
    get "/pickup_sports/games/#{game.id}"
    page = Capybara.string(response.body)
    expect(page).to have_text("Attendance closed")
    expect(page).to have_text("Ready Player")
    expect(page).to have_css("button[aria-pressed='true']", text: "Absent")
    expect(response.body).not_to include("Join game", "Leave game")

    patch "/pickup_sports/games/#{game.id}/roster_entries/#{player_entry.id}/attendance",
          params: { attendance_status: "attended" }
    get "/pickup_sports/games/#{game.id}"
    corrected_page = Capybara.string(response.body)
    expect(corrected_page).to have_css("button[aria-pressed='true']", text: "Attended")
    expect(player_entry.reload).to be_attended
  end

  def sign_in(user)
    post "/login", params: { email: user.email, password: "s3cret-password" }
  end
end
