namespace :sentry do
  desc "Send a controlled event and flush it to verify the production Sentry connection"
  task smoke_test: :environment do
    unless Sentry.initialized? && Sentry.configuration.sending_allowed?
      abort "Sentry is disabled here. Check SENTRY_DSN, SENTRY_ENVIRONMENT, and SENTRY_ENABLED_ENVIRONMENTS."
    end

    event = Sentry.capture_message(
      "CitySocial Sentry smoke test",
      level: :info,
      tags: { source: "rake", smoke_test: true }
    )
    Sentry.get_current_client.flush

    abort "Sentry did not accept the smoke-test event." unless event

    puts "Sentry smoke test sent: event_id=#{event.event_id}"
  end
end
