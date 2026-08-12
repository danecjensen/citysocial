max_threads = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
min_threads = Integer(ENV.fetch("RAILS_MIN_THREADS", max_threads))
threads min_threads, max_threads

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

workers Integer(ENV.fetch("WEB_CONCURRENCY", 1))
preload_app!

on_worker_boot do
  next unless ENV.fetch("RAILS_ENV", "development") == "production"

  # Pay the database connection/configuration cost while the worker boots so a
  # real user's first request never has to. The pool keeps this connection warm
  # because production sets idle_timeout to zero.
  ActiveRecord::Base.connection_pool.with_connection do |connection|
    connection.execute("SELECT 1")
  end
end

plugin :tmp_restart
