# frozen_string_literal: true

module I18nFeedback
  # Host-tunable settings. Everything has a safe default, so a fresh install works
  # with zero configuration in development; the hooks below let an app decide who
  # sees the tool and how suggestions are attributed.
  class Configuration
    # Environments the tool is active in. It is never active anywhere else, so a
    # production deploy can't accidentally expose the key markers or the endpoint.
    attr_accessor :enabled_environments

    # Per-request gate, on top of the environment check. Return false to hide the
    # tool for this request. Receives the Rack::Request. Plug in an admin check, a
    # feature flag, an allowlist, etc.
    attr_accessor :enabled

    # Resolve the current user for attribution (optional). Return an object
    # responding to #id, or nil. Receives the Rack::Request.
    attr_accessor :current_user

    # Turn a resolved user into a short label shown in the "already suggested"
    # list. Receives whatever #current_user returned.
    attr_accessor :author_label

    # The locales a suggestion may target. Used to validate submissions.
    attr_accessor :available_locales

    # Inject the widget into HTML responses automatically. Set false to place it
    # yourself with `<%= i18n_feedback_tag %>` in your layout.
    attr_accessor :auto_inject

    # Where the engine is mounted. The widget posts suggestions to
    # "#{mount_path}/suggestions", so keep this in sync with the `mount` line in
    # your routes.
    attr_accessor :mount_path

    # Show the floating toggle pill. Set false to hide it and drive suggest mode
    # from your own link instead (see #toggle_param).
    attr_accessor :show_pill

    # Text on the floating toggle pill. Leave nil to use the localized default
    # ("Suggest edits", translated via the `i18n_feedback.pill` I18n key).
    attr_accessor :pill_label

    # The query-string parameter that turns suggest mode on/off, so a host can
    # link to it from anywhere: "?i18n_feedback=true" enables it, "false" exits.
    # The choice is remembered in a cookie, so the rest of the app stays in
    # suggest mode without the parameter.
    attr_accessor :toggle_param

    # Called with each saved suggestion — notify Slack, send an email, open a
    # ticket. Runs inline after save; keep it fast or hand off to a job.
    attr_accessor :on_submit

    def initialize
      @enabled_environments = %w[development staging]
      @enabled = ->(_request) { true }
      @current_user = ->(_request) {}
      @author_label = ->(user) { user.respond_to?(:email) ? user.email : user&.to_s }
      @available_locales = -> { I18n.available_locales.map(&:to_s) }
      @auto_inject = true
      @mount_path = '/i18n_feedback'
      @show_pill = true
      @pill_label = nil
      @toggle_param = 'i18n_feedback'
      @on_submit = ->(_suggestion) {}
    end

    def environment_enabled?
      enabled_environments.map(&:to_s).include?(Rails.env.to_s)
    end

    def suggestions_endpoint
      "#{mount_path.chomp('/')}/suggestions"
    end
  end
end
