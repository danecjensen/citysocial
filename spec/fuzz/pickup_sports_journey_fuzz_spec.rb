require "rails_helper"

# Tunables for the journey below. They live in a real module (not in the
# example group body) so the linter's constant-in-block rule stays happy, and
# they are exposed as readers so the example group can just `include` them.
module PickupSportsJourneyFuzz
  # Relative frequency of each action in the generated journey. Joins dominate
  # so rosters actually fill and spill onto the waitlist; clock moves are rare
  # because they retire games permanently.
  ACTION_WEIGHTS = {
    join: 10,
    leave: 6,
    create_game: 3,
    raise_capacity: 2,
    advance_clock: 1,
    cancel: 1
  }.freeze
  RESIDENT_COUNT = 8
  CAPACITY_RANGE = (2..3)
  # Small pools keep contention (and therefore waitlists) high.
  MAX_LIVE_GAMES = 2
  MAX_GAMES = 6
  # 1-in-N actions target any game, including canceled/expired ones, which
  # exercises the refusal paths; the rest target a game that can still change.
  LIVE_GAME_BIAS = 4
  # Secret-ish copy that must never reach the event bus.
  PRIVATE_DETAILS = "Door code 4821 stays inside the module.".freeze

  def action_weights = ACTION_WEIGHTS
  def resident_count = RESIDENT_COUNT
  def capacity_range = CAPACITY_RANGE
  def max_live_games = MAX_LIVE_GAMES
  def max_games = MAX_GAMES
  def live_game_bias = LIVE_GAME_BIAS
  def private_details = PRIVATE_DETAILS
end

# Deterministic, stateful journey fuzzer for the pickup sports roster.
#
# A pseudo-random sequence of resident actions (host a game, join, leave,
# cancel, edit capacity, let the clock run) is replayed against the real
# models inside the example transaction. Every step is mirrored in a tiny
# in-memory oracle that encodes the documented semantics of
# PickupSports::Game, and after every action the database is compared to the
# oracle and checked against invariants that must hold no matter what.
#
# Controls (both spellings accepted):
#   FUZZ_SEED  / JOURNEY_SEED   integer seed for the local Random  (default 1337)
#   FUZZ_STEPS / JOURNEY_STEPS  number of actions to replay        (default 60)
#
# Failures print the full trace so any discovered bug is reproducible with
# `FUZZ_SEED=<seed> FUZZ_STEPS=<steps> bundle exec rspec spec/fuzz/...`.
RSpec.describe "pickup sports journey fuzz", type: :model do
  include ActiveSupport::Testing::TimeHelpers
  include PickupSportsJourneyFuzz

  before do
    # Isolate the bus during the journey, then restore its boot-time subscribers
    # exactly so this fuzzer remains independent of RSpec example order.
    @original_event_registry = PlatformCore::EventBus.registry.transform_values(&:dup)
    PlatformCore::EventBus.reset!
    @published = []
    %w[
      pickup_sports.game_created
      pickup_sports.game_changed
      pickup_sports.roster_changed
      pickup_sports.roster_promoted
    ].each do |event_name|
      PlatformCore::EventBus.subscribe(event_name, ->(name, payload) { @published << [name, payload] })
    end
  end

  # The frozen clock needs no explicit `travel_back`: rspec-rails runs Minitest's
  # `after_teardown` from an `around` hook, and ActiveSupport's TimeHelpers hooks
  # `travel_back` onto it, so the clock is restored even when the example raises.
  after do
    PlatformCore::EventBus.reset!
    @original_event_registry&.each do |event_name, subscriptions|
      PlatformCore::EventBus.registry[event_name].concat(subscriptions)
    end
  end

  it "keeps rosters, seats and projections consistent across a random action journey" do
    start_journey
    fuzz_steps.times { |step| take_step(step) }

    expect(@games).not_to be_empty
    expect(@published.map(&:first).uniq).to include("pickup_sports.game_created")
  rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
    raise e.exception("#{e.message}\n\n#{trace_report}")
  end

  # ---------------------------------------------------------------- controls

  def fuzz_seed
    Integer(ENV.fetch("FUZZ_SEED", nil) || ENV.fetch("JOURNEY_SEED", nil) || "1337", 10)
  end

  def fuzz_steps
    Integer(ENV.fetch("FUZZ_STEPS", nil) || ENV.fetch("JOURNEY_STEPS", nil) || "60", 10)
  end

  # ------------------------------------------------------------------ driver

  def start_journey
    @random = Random.new(fuzz_seed)
    @trace = []
    @expected_promotions = 0
    @games = []
    # Freeze the clock so ordering, timestamps and `future?` boundaries are
    # reproducible; `advance_clock` steps move it forward explicitly.
    travel_to(Time.zone.local(2031, 4, 12, 9, 0, 0))
    @residents = Array.new(resident_count) { create(:user) }
    log(-1, "start", "seed=#{fuzz_seed} steps=#{fuzz_steps} residents=#{@residents.map(&:id).inspect}")
    act_create_game(0)
    assert_invariants(0)
  end

  def take_step(step)
    action = weighted_actions.sample(random: @random)
    send(:"act_#{action}", step)
    assert_invariants(step)
  end

  def weighted_actions
    action_weights.flat_map { |action, weight| Array.new(weight, action) }
  end

  def log(step, action, message)
    @trace << format("%<step>4d  %<action>-14s %<message>s", step: step, action: action, message: message)
  end

  def trace_report
    ["--- journey trace (FUZZ_SEED=#{fuzz_seed} FUZZ_STEPS=#{fuzz_steps}) ---", *@trace].join("\n")
  end

  # ----------------------------------------------------------------- actions

  def act_create_game(step)
    if @games.size >= max_games || live_games.size >= max_live_games
      return log(step, "create_game", "skipped: game pool full")
    end

    host = pick_resident
    capacity = @random.rand(capacity_range)
    starts_at = Time.current + @random.rand(30..2_880).minutes
    game = create(
      :pickup_sports_game,
      host: host,
      capacity: capacity,
      starts_at: starts_at,
      details: private_details,
      sport: PickupSports::Game::SPORTS.sample(random: @random),
      skill_level: PickupSports::Game::SKILL_LEVELS.sample(random: @random)
    )
    @games << {
      id: game.id, host_id: host.id, capacity: capacity, status: "open",
      starts_at: game.starts_at, entries: [[host.id, "joined"]], capacity_raised: false
    }
    log(step, "create_game", "game=#{game.id} host=#{host.id} capacity=#{capacity} starts_at=#{stamp(starts_at)}")
  end

  def act_join(step)
    model = pick_game
    resident = pick_joiner(model)
    game = reload_game(model)
    log(step, "join", "game=#{model[:id]} resident=#{resident.id} joinable=#{model_joinable?(model)}")

    unless model_joinable?(model)
      expect { game.join!(resident.id) }.to raise_error(PickupSports::Game::ParticipationError)
      return
    end

    existing = model_entry(model, resident.id)
    unless existing
      status = model_joined_count(model) < model[:capacity] ? "joined" : "waitlisted"
      model[:entries] << [resident.id, status]
    end
    entry = game.join!(resident.id)

    expect(entry).to be_a(PickupSports::RosterEntry)
    expect(entry.resident_id).to eq(resident.id)
    expect(entry.status).to eq(model_entry(model, resident.id).last)
  end

  def act_leave(step)
    model = pick_game
    resident_id = pick_leaver(model)
    game = reload_game(model)
    log(step, "leave", "game=#{model[:id]} resident=#{resident_id} host=#{model[:host_id]}")

    if resident_id == model[:host_id]
      expect { game.leave!(resident_id) }.to raise_error(PickupSports::Game::ParticipationError, /Hosts stay/)
      return
    end

    expected_promotion = apply_expected_leave(model, resident_id)
    promoted = game.leave!(resident_id)

    expect(promoted&.resident_id).to eq(expected_promotion)
    expect(promoted&.status).to eq(expected_promotion && "joined")
  end

  def act_cancel(step)
    model = pick_game
    game = reload_game(model)
    log(step, "cancel", "game=#{model[:id]} was=#{model[:status]}")

    game.cancel!
    model[:status] = "canceled"

    expect(reload_game(model)).to be_canceled
  end

  def act_raise_capacity(step)
    model = pick_game
    new_capacity = [model[:capacity] + @random.rand(1..3), 100].min
    if new_capacity == model[:capacity]
      return log(step, "raise_capacity", "game=#{model[:id]} skipped: already at maximum")
    end

    game = reload_game(model)
    log(step, "raise_capacity", "game=#{model[:id]} #{model[:capacity]} -> #{new_capacity}")

    game.update!(capacity: new_capacity)
    model[:capacity] = new_capacity
    # Raising capacity does not auto-promote: once idle waitlisters exist for
    # this game, stop asserting the "no idle waitlist" invariant on it.
    model[:capacity_raised] = true if model_waitlisted_count(model).positive?

    expect(reload_game(model).capacity).to eq(model[:capacity])
  end

  def act_advance_clock(step)
    minutes = @random.rand(5..240)
    travel_to(Time.current + minutes.minutes)
    log(step, "advance_clock", "+#{minutes}m now=#{stamp(Time.current)}")
  end

  # ------------------------------------------------------------------ oracle

  def apply_expected_leave(model, resident_id)
    entry = model_entry(model, resident_id)
    return nil unless entry

    was_joined = entry.last == "joined"
    model[:entries].delete(entry)
    return nil unless was_joined && model_joinable?(model)

    promoted = model[:entries].find { |_id, status| status == "waitlisted" }
    return nil unless promoted

    promoted[1] = "joined"
    @expected_promotions += 1
    promoted.first
  end

  def model_joinable?(model)
    model[:status] == "open" && model[:starts_at] > Time.current
  end

  def model_entry(model, resident_id)
    model[:entries].find { |id, _status| id == resident_id }
  end

  def model_joined_count(model)
    model[:entries].count { |_id, status| status == "joined" }
  end

  def model_waitlisted_count(model)
    model[:entries].count { |_id, status| status == "waitlisted" }
  end

  # -------------------------------------------------------------- invariants

  def assert_invariants(step)
    @games.each { |model| assert_game_invariants(step, model) }
    assert_upcoming_projection
    assert_event_invariants
  end

  def assert_game_invariants(step, model)
    game = reload_game(model)
    entries = game.roster_entries.order(:created_at, :id).to_a
    joined = entries.count(&:joined?)
    context = "step=#{step} game=#{model[:id]}"

    # The oracle and the database agree on the whole roster, in queue order.
    expect(entries.map { |entry| [entry.resident_id, entry.status] }).to eq(model[:entries]), context
    expect(entries.map(&:status) - PickupSports::RosterEntry::STATUSES).to be_empty, context

    # One entry per resident, and the host is never dropped from the roster.
    expect(entries.map(&:resident_id).uniq.size).to eq(entries.size), context
    expect(entries.find { |entry| entry.resident_id == game.host_id }&.status).to eq("joined"), context

    # Seats are never oversold and the derived helpers stay consistent.
    expect(joined).to be <= game.capacity, context
    expect(game.joined_count).to eq(joined), context
    expect(game.waitlisted_count).to eq(entries.count(&:waitlisted?)), context
    expect(game.seats_remaining).to eq([game.capacity - joined, 0].max), context
    expect(game.full?).to eq(joined >= game.capacity), context
    expect(game.joinable?).to eq(model_joinable?(model)), context
    expect(game.capacity).to eq(model[:capacity]), context
    expect(game.status).to eq(model[:status]), context

    # A raised capacity legitimately strands the existing waitlist (the model
    # deliberately does not auto-promote), so the queue-shape invariants below
    # are suspended for that game until its waitlist drains.
    model[:capacity_raised] = false if entries.none?(&:waitlisted?)
    return if model[:capacity_raised]

    # Joined players always sit ahead of waitlisted ones in the queue: joins
    # append, and promotions always take the head of the waitlist.
    expect(entries.map(&:status)).to eq(entries.map(&:status).sort_by { |s| s == "joined" ? 0 : 1 }), context
    return if joined >= game.capacity || !game.joinable?

    # Nobody waits while a seat is free on a game that can still promote.
    expect(entries.select(&:waitlisted?)).to be_empty, context
  end

  def assert_upcoming_projection
    now = Time.current
    expected = @games
               .select { |model| model[:status] == "open" && model[:starts_at] >= now }
               .sort_by { |model| [model[:starts_at], model[:id]] }
               .map { |model| [model[:id], model_joined_count(model), model_waitlisted_count(model)] }
    actual = PickupSports::UpcomingGames.call(limit: 50).map do |summary|
      [summary.id, summary.joined_count, summary.waitlisted_count]
    end

    expect(actual).to eq(expected)
  end

  def assert_event_invariants
    game_ids = @games.map { |model| model[:id] }
    counts = @published.group_by(&:first).transform_values(&:size)

    @published.each do |name, payload|
      expect(payload[:game_id]).to be_in(game_ids), name
      expect(payload[:target_path]).to eq("/pickup_sports/games/#{payload[:game_id]}"), name
      expect(payload.values).to all(be_a(Integer).or(be_a(String)))
    end
    expect(@published.to_s).not_to include(private_details)
    expect(counts.fetch("pickup_sports.game_created", 0)).to eq(@games.size)
    expect(counts.fetch("pickup_sports.roster_promoted", 0)).to eq(@expected_promotions)
  end

  # ------------------------------------------------------------------ helpers

  def pick_resident
    @residents.sample(random: @random)
  end

  # Mostly bring in someone new so waitlists grow deep; occasionally re-join an
  # existing member to exercise the idempotent path.
  def pick_joiner(model)
    newcomers = @residents.reject { |resident| model_entry(model, resident.id) }
    return pick_resident if newcomers.empty? || @random.rand(6).zero?

    newcomers.sample(random: @random)
  end

  # Mostly drop a seated (non-host) player so promotions actually fire;
  # occasionally pick anyone to exercise the host guard and the no-op path.
  def pick_leaver(model)
    seated = model[:entries].filter_map { |id, status| id if status == "joined" && id != model[:host_id] }
    return pick_resident.id if seated.empty? || @random.rand(4).zero?

    seated.sample(random: @random)
  end

  def pick_game
    pool = live_games
    return @games.sample(random: @random) if pool.empty? || @random.rand(live_game_bias).zero?

    pool.sample(random: @random)
  end

  def live_games
    @games.select { |model| model_joinable?(model) }
  end

  def reload_game(model)
    PickupSports::Game.find(model[:id])
  end

  def stamp(time)
    time.utc.iso8601
  end
end
