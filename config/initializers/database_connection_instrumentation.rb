# Measure the two database connection delays that can otherwise look identical
# in request logs: waiting for a pooled connection and opening a new connection.
# Only slow operations and failures are logged to keep request overhead and log
# volume low.
module DatabaseConnectionInstrumentation
  CHECKOUT_WARN_MS = Float(ENV.fetch("DB_CHECKOUT_WARN_MS", 100))
  CONNECT_WARN_MS = Float(ENV.fetch("DB_CONNECT_WARN_MS", 250))

  def checkout(...)
    started_at = monotonic_milliseconds
    error = nil

    super
  rescue StandardError => e
    error = e
    raise
  ensure
    log_database_connection_event("checkout", started_at, CHECKOUT_WARN_MS, error)
  end

  private

  def new_connection
    started_at = monotonic_milliseconds
    error = nil

    super
  rescue StandardError => e
    error = e
    raise
  ensure
    log_database_connection_event("connect", started_at, CONNECT_WARN_MS, error)
  end

  def monotonic_milliseconds
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
  end

  def log_database_connection_event(event, started_at, threshold_ms, error)
    duration_ms = monotonic_milliseconds - started_at
    return if error.nil? && duration_ms < threshold_ms

    pool_stats = stat
    fields = {
      event: "database_connection_#{event}",
      duration_ms: duration_ms.round(1),
      threshold_ms: threshold_ms,
      status: error.nil? ? "slow" : "error",
      error: error&.class&.name,
      pool: db_config.name,
      size: pool_stats[:size],
      connections: pool_stats[:connections],
      busy: pool_stats[:busy],
      idle: pool_stats[:idle],
      waiting: pool_stats[:waiting]
    }.compact

    Rails.logger.warn(fields.map { |key, value| "#{key}=#{value}" }.join(" "))
  rescue StandardError
    # Observability must never turn a slow checkout into a failed request.
    nil
  end
end

ActiveSupport.on_load(:active_record) do
  pool_class = ActiveRecord::ConnectionAdapters::ConnectionPool
  pool_class.prepend(DatabaseConnectionInstrumentation) unless pool_class < DatabaseConnectionInstrumentation
end
