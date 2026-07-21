# frozen_string_literal: true

module I18nFeedback
  # Appends a "⟦namespace.key⟧" marker to each translated string so the widget can
  # map rendered text back to its i18n key. The marker is never shown to the user:
  # the widget strips every token out of the DOM on load and stashes the key on the
  # element. Marking is a per-request, per-thread toggle (see Middleware), so pages
  # stay clean unless a proofreader has switched the tool on.
  module Marking
    LEFT = '⟦'
    RIGHT = '⟧'

    # Skip format/lookup namespaces — marking these would corrupt number, date,
    # and currency formatting and interpolation strings. The tool's own
    # `i18n_feedback.*` strings are skipped too: they aren't part of the host
    # app's translatable copy, so the widget must never mark (or offer to edit)
    # its own UI.
    SKIP = /(\A|\.)(number|date|time|datetime|support|i18n_feedback)(\.|\z)|formats?\z/

    class << self
      def enabled?
        Thread.current[:i18n_feedback_marking] || false
      end

      def enabled=(value)
        Thread.current[:i18n_feedback_marking] = value
      end
    end

    # Prepended onto the active I18n backend class.
    module Backend
      def translate(locale, key, options = {})
        result = super
        return result unless Marking.enabled? && result.is_a?(String)

        full = [*options[:scope], key].join('.')
        return result if full.match?(SKIP)

        # `super` returns a plain String even for _html keys (ActionView marks the
        # helper's output safe after the backend returns), so the marker lands
        # inside that buffer without changing any html_safe status.
        "#{result} #{LEFT}#{full}#{RIGHT}"
      end
    end
  end
end
