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
      # config, one carrying the widget itself. `nonce:` stamps both tags so the
      # widget runs under a nonce-based Content-Security-Policy (e.g. one using
      # 'strict-dynamic'); pass nil when the app has no CSP nonce.
      def snippet(endpoint:, locale:, active:, nonce: nil)
        config = {
          endpoint: endpoint,
          locale: locale.to_s,
          active: active ? true : false,
          showPill: I18nFeedback.config.show_pill ? true : false,
          pillLabel: I18nFeedback.config.pill_label
        }
        nonce_attr = nonce ? %( nonce="#{nonce}") : ''

        %(<script data-i18n-feedback#{nonce_attr}>window.__i18nFeedback=#{config.to_json};</script>) +
          %(<script data-i18n-feedback-widget#{nonce_attr}>#{javascript}</script>)
      end
    end
  end
end
