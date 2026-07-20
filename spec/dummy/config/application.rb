# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_record/railtie"
require "action_controller/railtie"

require "i18n_feedback"

# Turn the tool on for the test environment BEFORE the app initializes, so the
# key-marking backend is prepended during boot.
I18nFeedback.configure do |config|
  config.enabled_environments = %w[test]
end

module Dummy
  class Application < Rails::Application
    # Pin the root to spec/dummy; otherwise Rails walks up to the gem repo (it has
    # a Gemfile) and can't find config/database.yml.
    config.root = File.expand_path("..", __dir__)
    config.load_defaults 7.1
    config.eager_load = false
    config.secret_key_base = "i18n-feedback-dummy-secret"
    config.i18n.available_locales = %i[en fr]
    config.i18n.default_locale = :en

    # A nonce-based CSP, so specs can assert the injected widget is noncED.
    config.content_security_policy do |policy|
      policy.script_src :self
    end
    config.content_security_policy_nonce_generator = ->(_request) { 'testnonce' }
    config.content_security_policy_nonce_directives = %w[script-src]
  end
end
