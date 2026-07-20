# frozen_string_literal: true

require 'i18n_feedback/version'
require 'i18n_feedback/configuration'
require 'i18n_feedback/marking'
require 'i18n_feedback/widget'
require 'i18n_feedback/middleware'
require 'i18n_feedback/engine'

# In-context translation proofreading for Rails. Renders each i18n key alongside
# its text in the chosen environments, lets a proofreader click any string and
# suggest a better wording, and stores the suggestions for a developer to apply.
module I18nFeedback
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    # Is the tool available for this request? True only in an enabled environment
    # and when the host's `enabled` predicate passes. Checked on the server for
    # every marker, endpoint, and injection, so the client can never turn it on.
    def available?(request)
      config.environment_enabled? && !!config.enabled.call(request)
    end
  end
end
