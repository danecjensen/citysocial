# Keep credentials and resident-authored text out of Rails logs, Sentry spans,
# and any other instrumentation that uses request.filtered_parameters.
Rails.application.config.filter_parameters += [
  /passw|email|secret|token|_key|crypt|salt|certificate|otp|ssn|cvv|cvc|authorization|cookie/i,
  :body,
  :description,
  :bio,
  :details,
  :message,
  :q,
  :query
]
