# frozen_string_literal: true

require 'json'

module I18nFeedback
  # Serves the self-contained browser widget. The JavaScript is plain ES (no
  # framework, no build step) and styles itself inline, so it drops into any Rails
  # app regardless of its CSS or JS setup. It is inlined into the page rather than
  # served as a separate asset to avoid any dependency on the host's asset
  # pipeline.
  module Widget
    SOURCE = File.expand_path('../../app/assets/i18n_feedback/widget.js', __dir__)

    class << self
      def javascript
        @javascript ||= File.read(SOURCE)
      end

      # The two <script> tags to place before </body>: one carrying the runtime
      # config, one carrying the widget itself.
      def snippet(endpoint:, locale:, active:)
        config = { endpoint: endpoint, locale: locale.to_s, active: active ? true : false }

        %(<script data-i18n-feedback>window.__i18nFeedback=#{config.to_json};</script>) +
          %(<script data-i18n-feedback-widget>#{javascript}</script>)
      end
    end
  end
end
