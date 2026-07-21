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

      # The two <script> tags to place before </body>.
      #
      # The config rides in a `type="application/json"` block: it is *data*, not
      # code, so the browser never executes it and Turbo never tries to re-run it
      # on a soft visit — which means it needs no CSP nonce and, crucially, the
      # widget can re-read the *current* page's config on every `turbo:load`
      # instead of being stuck with whatever the last full load evaluated.
      #
      # `nonce:` stamps only the widget script (the code), so it runs under a
      # nonce-based Content-Security-Policy; pass nil when the app has no nonce.
      def snippet(endpoint:, locale:, active:, nonce: nil)
        config = {
          endpoint: endpoint,
          locale: locale.to_s,
          active: active ? true : false,
          showPill: I18nFeedback.config.show_pill ? true : false,
          pillLabel: I18nFeedback.config.pill_label,
          toggleParam: I18nFeedback.config.toggle_param
        }
        # Escape "</" so a value can't close the <script> block early.
        json = config.to_json.gsub('</', '<\/')
        nonce_attr = nonce ? %( nonce="#{nonce}") : ''

        %(<script type="application/json" data-i18n-feedback-config>#{json}</script>) +
          %(<script data-i18n-feedback-widget#{nonce_attr}>#{javascript}</script>)
      end
    end
  end
end
