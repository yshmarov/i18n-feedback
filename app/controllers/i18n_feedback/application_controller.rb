# frozen_string_literal: true

module I18nFeedback
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :require_available

    private

    # Server-side gate. The client can set the cookie, but it can never reach the
    # endpoints unless the app itself says the tool is available for this request.
    def require_available
      head :forbidden unless I18nFeedback.available?(request)
    end

    def current_author
      return @current_author if defined?(@current_author)

      @current_author = I18nFeedback.config.current_user.call(request)
    end
  end
end
