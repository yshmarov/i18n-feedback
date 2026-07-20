# frozen_string_literal: true

module I18nFeedback
  # Lets a host place the widget explicitly (`<%= i18n_feedback_tag %>` at the end
  # of a layout) instead of relying on auto-injection. Renders nothing unless the
  # tool is available for the current request.
  module TagHelper
    def i18n_feedback_tag
      return ''.html_safe unless I18nFeedback.available?(request)

      Widget.snippet(
        endpoint: I18nFeedback.config.suggestions_endpoint,
        locale: I18n.locale,
        active: I18nFeedback::Marking.enabled?
      ).html_safe
    end
  end
end
