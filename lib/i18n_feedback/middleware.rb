# frozen_string_literal: true

require 'rack'

module I18nFeedback
  # Runs on every request to (1) flip key-marking on for the duration of the
  # request when a proofreader has the tool switched on, and (2) inject the widget
  # into HTML responses so the host needs no layout changes. Both are strictly
  # gated by I18nFeedback.available?, so nothing happens in a disabled environment.
  class Middleware
    COOKIE = 'i18n_feedback'

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      available = I18nFeedback.available?(request)
      marking = available && !request.cookies[COOKIE].to_s.empty?
      Marking.enabled = marking

      status, headers, body = @app.call(env)

      if available && I18nFeedback.config.auto_inject && html?(headers) && !request.xhr?
        status, headers, body = inject(status, headers, body, marking)
      end

      [status, headers, body]
    ensure
      Marking.enabled = false
    end

    private

    def html?(headers)
      content_type(headers).to_s.include?('text/html')
    end

    def content_type(headers)
      headers['Content-Type'] || headers['content-type']
    end

    def inject(status, headers, body, marking)
      html = +''
      body.each { |part| html << part.to_s }
      body.close if body.respond_to?(:close)

      snippet = Widget.snippet(
        endpoint: I18nFeedback.config.suggestions_endpoint,
        locale: I18n.locale,
        active: marking
      )
      html = html.include?('</body>') ? html.sub('</body>', "#{snippet}</body>") : html + snippet

      headers = headers.dup
      headers['Content-Length'] = html.bytesize.to_s if headers.key?('Content-Length') || headers.key?('content-length')

      [status, headers, [html]]
    end
  end
end
