# frozen_string_literal: true

I18nFeedback.configure do |config|
  # Environments the tool is active in. It is never active anywhere else.
  config.enabled_environments = %w[development staging]

  # Per-request gate on top of the environment check. Return false to hide the
  # tool. Receives the Rack::Request — plug in an admin check, a feature flag, an
  # IP allowlist, etc.
  #
  # config.enabled = ->(request) { true }

  # Attribute a suggestion to a user (optional). Return an object responding to
  # #id (ideally #email too), or nil. Receives the Rack::Request. You resolve the
  # user however your app does — session, Warden, a token, etc.
  #
  # config.current_user = ->(request) { nil }

  # How to label the author in the "already suggested" list.
  #
  # config.author_label = ->(user) { user.try(:email) }

  # The widget is injected into HTML responses automatically. Set this to false to
  # place it yourself with `<%= i18n_feedback_tag %>` at the end of your layout.
  #
  # config.auto_inject = true

  # Show the floating "Suggest edits" pill. Set false to hide it and toggle
  # suggest mode from your own link instead, e.g.
  # `<%= link_to "Proofread", "?i18n_feedback=true" %>`. "?i18n_feedback=false"
  # exits; the choice is remembered in a cookie.
  #
  # config.show_pill = true
  # config.toggle_param = "i18n_feedback"

  # Keep this in sync with the `mount` line in config/routes.rb.
  #
  # config.mount_path = "/i18n_feedback"
end
