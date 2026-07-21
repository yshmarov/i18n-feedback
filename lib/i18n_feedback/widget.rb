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

    # Right-to-left scripts, so the popover renders mirrored for those locales.
    # Matched on the language subtag, so region variants ("ar-EG") count too.
    RTL_LANGUAGES = %w[ar arc ckb dv fa ha he ks ku ps sd ug ur yi].freeze

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
          toggleParam: I18nFeedback.config.toggle_param,
          labels: labels,
          rtl: rtl?(locale)
        }
        # Escape "</" so a value can't close the <script> block early.
        json = config.to_json.gsub('</', '<\/')
        nonce_attr = nonce ? %( nonce="#{nonce}") : ''

        %(<script type="application/json" data-i18n-feedback-config>#{json}</script>) +
          %(<script data-i18n-feedback-widget#{nonce_attr}>#{javascript}</script>)
      end

      private

      # Every user-facing string in the widget, resolved through Rails I18n so the
      # popover follows the app's current locale. Each lookup carries an English
      # default, so the widget stays fully worded even when the host app hasn't
      # loaded the gem's locale file or is missing a key for the active locale.
      def labels
        {
          pill: t(:pill, 'Suggest edits'),
          pillActive: t(:pill_active, 'Suggesting — tap to exit (Esc)'),
          title: t(:title, 'Suggest a translation fix'),
          currentText: t(:current_text, 'Current text'),
          suggestedText: t(:suggested_text, 'Suggested text'),
          comment: t(:comment, 'Comment'),
          commentPlaceholder: t(:comment_placeholder, 'Optional note for the developer'),
          priorTitle: t(:prior_title, 'Already suggested (pending)'),
          cancel: t(:cancel, 'Cancel'),
          save: t(:save, 'Send suggestion'),
          errorBlank: t(:error_blank, 'Please enter a suggestion.'),
          errorSave: t(:error_save, 'Could not save the suggestion.')
        }
      end

      def t(key, default)
        I18n.t(key, scope: :i18n_feedback, default: default)
      end

      def rtl?(locale)
        RTL_LANGUAGES.include?(locale.to_s.downcase.split(/[-_]/).first)
      end
    end
  end
end
