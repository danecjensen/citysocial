require "rails_helper"

module RequestFuzz
  DEFAULT_REQUESTS = 60
  DEFAULT_MAX_REQUEST_MS = 500.0
  DEFAULT_MAX_SINGLE_REQUEST_MS = 2_000.0
  DEFAULT_MAX_SQL_QUERIES = 50
  EXTREME_PAGE = "2147483647".freeze
  LONG_QUERY = ("fuzz_%'\\" * 256).freeze
  ODD_QUERIES = [
    "",
    "   ",
    "%_",
    "' OR 1=1 --",
    "💥 café 東京",
    LONG_QUERY
  ].freeze
  IGNORED_SQL_NAMES = %w[SCHEMA TRANSACTION].freeze
end

# Deterministic anonymous-request fuzzer for public, read-only surfaces.
#
# Controls:
#   FUZZ_SEED             local Random seed                 (default 1337)
#   FUZZ_REQUESTS              number of GET requests              (default 60)
#   FUZZ_MAX_REQUEST_MS        maximum p95 request time            (default 500)
#   FUZZ_MAX_SINGLE_REQUEST_MS hard limit for one request          (default 2000)
#   FUZZ_MAX_SQL_QUERIES       maximum SQL queries per request     (default 50)
RSpec.describe "public request fuzz", type: :request do
  include RequestFuzz

  before do
    @random = Random.new(fuzz_seed)
    @records = create_representative_records
    @measurements = []
  end

  it "avoids server errors and stays within request performance budgets" do
    warm_request_stack
    failures = fuzz_requests.filter_map { |request| exercise(request) }
    failures.concat(performance_failures)
    print_performance_summary

    expect(failures).to be_empty, "Request fuzz failures:\n#{failures.join("\n")}"
  end

  private

  def fuzz_seed
    Integer(ENV.fetch("FUZZ_SEED", "1337"), 10)
  end

  def fuzz_request_count
    positive_integer_env("FUZZ_REQUESTS", RequestFuzz::DEFAULT_REQUESTS)
  end

  def max_request_ms
    positive_float_env("FUZZ_MAX_REQUEST_MS", RequestFuzz::DEFAULT_MAX_REQUEST_MS)
  end

  def max_single_request_ms
    positive_float_env("FUZZ_MAX_SINGLE_REQUEST_MS", RequestFuzz::DEFAULT_MAX_SINGLE_REQUEST_MS)
  end

  def max_sql_queries
    positive_integer_env("FUZZ_MAX_SQL_QUERIES", RequestFuzz::DEFAULT_MAX_SQL_QUERIES)
  end

  def positive_integer_env(name, default)
    value = Integer(ENV.fetch(name, default.to_s), 10)
    raise ArgumentError, "#{name} must be positive" unless value.positive?

    value
  end

  def positive_float_env(name, default)
    value = Float(ENV.fetch(name, default.to_s))
    raise ArgumentError, "#{name} must be positive" unless value.positive?

    value
  end

  def create_representative_records
    resident = create(
      :user,
      handle: "request_fuzz_resident",
      display_name: "Request Fuzz Resident",
      neighborhood: "North Loop",
      bio: "A representative public profile."
    )
    neighbor = create(:user, handle: "request_fuzz_neighbor")
    event = create(:event, title: "Request Fuzz Concert", starts_at: 2.days.from_now)
    create(:event, title: "Request Fuzz Film", category: "film", starts_at: 30.days.from_now)
    create(:listing, author_id: resident.id, title: "Request Fuzz Bicycle")
    create(:listing, author_id: neighbor.id, title: "Request Fuzz Apartment", category: "housing_rent")
    community = create(:community, creator_id: resident.id, name: "request_fuzzers")
    community_post = create(:community_post, community: community, author_id: neighbor.id)
    Communities::Comment.create!(post: community_post, author_id: resident.id, body: "Representative comment")
    game = create(:pickup_sports_game, host: resident, title: "Request Fuzz Soccer")
    create(:pickup_sports_roster_entry, game: game, resident_id: neighbor.id)
    feedback = create(:feedback_submission, author_id: resident.id, title: "Request fuzz feedback idea")

    {
      community: community,
      community_post: community_post,
      event: event,
      feedback: feedback,
      game: game,
      resident: resident
    }
  end

  def fuzz_requests
    corpus = request_corpus.shuffle(random: @random)
    Array.new(fuzz_request_count) do |index|
      mutate_request(corpus.fetch(index % corpus.length), index)
    end
  end

  def mutate_request(base_request, index)
    params = base_request.fetch(:params).merge(
      "_fuzz" => generated_query(index),
      "_fuzz_page" => @random.rand(-10_000..2_147_483_647).to_s
    )
    request(base_request.fetch(:path), params)
  end

  def generated_query(index)
    value = case @random.rand(6)
            when 0 then RequestFuzz::ODD_QUERIES.sample(random: @random)
            when 1 then "🔥" * @random.rand(1..64)
            when 2 then "a" * @random.rand(0..4_096)
            when 3 then [0, 1, 255, 256].pack("C*")
            when 4 then "../" * @random.rand(1..32)
            else { fuzz: index, nested: [nil, true, RequestFuzz::EXTREME_PAGE] }
            end
    value.is_a?(String) ? "#{index}:#{value}" : value
  end

  def request_corpus
    ordinary_requests + query_edge_requests + missing_record_requests
  end

  def ordinary_requests
    community = @records.fetch(:community)
    post = @records.fetch(:community_post)
    event = @records.fetch(:event)
    feedback = @records.fetch(:feedback)
    game = @records.fetch(:game)
    resident = @records.fetch(:resident)

    [
      request("/"),
      request("/login"),
      request("/signup"),
      request("/design"),
      request("/feed"),
      request("/events"),
      request("/events/all"),
      request("/events/e/#{event.id}"),
      request("/events/e/#{event.id}/calendar"),
      request("/marketplace"),
      request("/communities"),
      request("/communities/#{community.slug}"),
      request("/communities/#{community.slug}/posts/#{post.id}"),
      request("/pickup_sports"),
      request("/pickup_sports/games/#{game.id}"),
      request("/restaurants"),
      request("/restaurants/leaderboard"),
      request("/feedback"),
      request("/feedback/submissions/#{feedback.id}"),
      request("/people/#{resident.handle}")
    ]
  end

  def query_edge_requests
    community = @records.fetch(:community)
    post = @records.fetch(:community_post)

    [
      request("/events/all", q: odd_query, category: "not-a-category", page: "0"),
      request("/events/all", q: odd_query, category: "%_", page: "-999999"),
      request("/events/all", q: odd_query, page: RequestFuzz::EXTREME_PAGE),
      request("/marketplace", q: odd_query, category: "not-a-category", sort: "not-a-sort"),
      request("/marketplace", q: RequestFuzz::LONG_QUERY, category: "%_", sort: "price_desc"),
      request("/communities/#{community.slug}/posts/#{post.id}", sort: odd_query),
      request("/pickup_sports", sport: "not-a-sport", neighborhood: odd_query, on: "not-a-date"),
      request("/pickup_sports", sport: "%_", neighborhood: RequestFuzz::LONG_QUERY, on: "9999-99-99"),
      request("/feedback", q: odd_query, kind: "not-a-kind", status: "???", area: "../admin", sort: "sideways"),
      request(
        "/feedback",
        q: RequestFuzz::LONG_QUERY,
        kind: "%_",
        status: "-1",
        area: RequestFuzz::LONG_QUERY
      ),
      request("/login", return_to: RequestFuzz::LONG_QUERY),
      request("/signup", unexpected: odd_query)
    ]
  end

  def missing_record_requests
    community = @records.fetch(:community)

    [
      request("/events/e/0"),
      request("/events/e/not-an-id"),
      request("/events/e/#{RequestFuzz::EXTREME_PAGE}/calendar"),
      request("/marketplace/definitely-missing-listing"),
      request("/communities/definitely_missing"),
      request("/communities/#{community.slug}/posts/0", sort: odd_query),
      request("/communities/#{community.slug}/posts/not-an-id"),
      request("/pickup_sports/games/0"),
      request("/pickup_sports/games/not-an-id"),
      request("/feedback/submissions/0"),
      request("/feedback/submissions/not-an-id"),
      request("/people/definitely_missing")
    ]
  end

  def request(path, params = {})
    { path: path, params: params }
  end

  def odd_query
    RequestFuzz::ODD_QUERIES.sample(random: @random)
  end

  def exercise(request)
    sql_count = 0
    error = nil
    started_at = monotonic_time

    subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
      sql_count += 1 if count_sql?(payload)
    end

    begin
      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get request.fetch(:path), params: request.fetch(:params)
      end
    rescue StandardError => e
      error = e
    end

    elapsed_ms = (monotonic_time - started_at) * 1_000
    status = error ? "raised(#{error.class})" : response.status
    @measurements << { path: request.fetch(:path), ms: elapsed_ms, sql: sql_count }
    violations = []
    violations << "exception=#{error.class}: #{error.message}" if error
    violations << "5xx" if !error && response.server_error?
    violations << "request_ms>#{max_single_request_ms}" if elapsed_ms > max_single_request_ms
    violations << "sql_queries>#{max_sql_queries}" if sql_count > max_sql_queries
    return if violations.empty?

    format(
      "seed=%<seed>d path=%<path>s params=%<params>s status=%<status>s ms=%<ms>.2f sql=%<sql>d failures=%<failures>s",
      seed: fuzz_seed,
      path: request.fetch(:path),
      params: request.fetch(:params).inspect,
      status: status,
      ms: elapsed_ms,
      sql: sql_count,
      failures: violations.join(", ")
    )
  end

  def warm_request_stack
    ["/events", "/marketplace", "/communities", "/pickup_sports", "/feedback"].each { |path| get path }
  end

  def performance_failures
    stats = performance_stats
    return [] if stats.fetch(:p95).fetch(:ms) <= max_request_ms

    [format(
      "seed=%<seed>d p95_ms=%<p95>.2f budget_ms=%<budget>.2f slowest=%<path>s(%<max>.2fms)",
      seed: fuzz_seed,
      p95: stats.fetch(:p95).fetch(:ms),
      budget: max_request_ms,
      path: stats.fetch(:slowest).fetch(:path),
      max: stats.fetch(:slowest).fetch(:ms)
    )]
  end

  def print_performance_summary
    stats = performance_stats
    puts format(
      "Request fuzz: count=%<count>d p95=%<p95>.2fms max=%<max>.2fms (%<slow_path>s) max_sql=%<sql>d (%<sql_path>s)",
      count: @measurements.length,
      p95: stats.fetch(:p95).fetch(:ms),
      max: stats.fetch(:slowest).fetch(:ms),
      slow_path: stats.fetch(:slowest).fetch(:path),
      sql: stats.fetch(:noisiest).fetch(:sql),
      sql_path: stats.fetch(:noisiest).fetch(:path)
    )
  end

  def performance_stats
    ordered = @measurements.sort_by { |measurement| measurement.fetch(:ms) }
    {
      p95: ordered.fetch((ordered.length * 0.95).ceil - 1),
      slowest: ordered.last,
      noisiest: @measurements.max_by { |measurement| measurement.fetch(:sql) }
    }
  end

  def count_sql?(payload)
    !payload[:cached] && RequestFuzz::IGNORED_SQL_NAMES.exclude?(payload[:name])
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
