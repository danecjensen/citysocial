max_threads = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
min_threads = Integer(ENV.fetch("RAILS_MIN_THREADS", max_threads))
threads min_threads, max_threads

port ENV.fetch("PORT", 3000)
environment ENV.fetch("RAILS_ENV", "development")

workers Integer(ENV.fetch("WEB_CONCURRENCY", 1))
preload_app!

plugin :tmp_restart
