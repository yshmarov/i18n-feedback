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

      # A "?i18n_feedback=true|false" in the URL is a command: it overrides the
      # cookie for this request and is remembered so the rest of the app stays in
      # (or out of) suggest mode without the parameter.
      override = available ? toggle_override(request) : nil
      marking = available && (override.nil? ? cookie_on?(request) : override)
      Marking.enabled = marking

      status, headers, body = @app.call(env)

      headers = persist_choice(headers, override) if available && !override.nil?

      if available && I18nFeedback.config.auto_inject && html?(headers) && !request.xhr?
        status, headers, body = inject(status, headers, body, marking, csp_nonce(env))
      end

      [status, headers, body]
    ensure
      Marking.enabled = false
    end

    private

    def cookie_on?(request)
      !request.cookies[COOKIE].to_s.empty?
    end

    # The request's CSP nonce, so the injected scripts run under a nonce-based
    # Content-Security-Policy. Reads the value Rails memoizes on the env, which is
    # the same nonce the CSP header uses. nil when the app sets no nonce.
    def csp_nonce(env)
      return nil unless defined?(ActionDispatch::Request)

      ActionDispatch::Request.new(env).content_security_policy_nonce
    rescue StandardError
      nil
    end

    def toggle_override(request)
      param = I18nFeedback.config.toggle_param
      return nil unless request.params.key?(param)

      %w[1 true on yes].include?(request.params[param].to_s.strip.downcase)
    end

    def persist_choice(headers, desired)
      headers = headers.dup
      cookie = if desired
                 "#{COOKIE}=1; path=/; SameSite=Lax"
               else
                 "#{COOKIE}=; path=/; max-age=0; SameSite=Lax"
               end
      key = header_key(headers, 'set-cookie') || 'set-cookie'
      existing = headers[key]
      headers[key] = case existing
                     when nil then cookie
                     when Array then existing + [cookie]
                     else "#{existing}\n#{cookie}"
                     end
      headers
    end

    def header_key(headers, name)
      headers.key?(name) ? name : headers.keys.find { |k| k.to_s.casecmp?(name) }
    end

    def html?(headers)
      content_type(headers).to_s.include?('text/html')
    end

    def content_type(headers)
      headers['Content-Type'] || headers['content-type']
    end

    def inject(status, headers, body, marking, nonce)
      html = +''
      body.each { |part| html << part.to_s }
      body.close if body.respond_to?(:close)

      snippet = Widget.snippet(
        endpoint: I18nFeedback.config.suggestions_endpoint,
        locale: I18n.locale,
        active: marking,
        nonce: nonce
      )
      html = html.include?('</body>') ? html.sub('</body>', "#{snippet}</body>") : html + snippet

      headers = headers.dup
      headers['Content-Length'] = html.bytesize.to_s if headers.key?('Content-Length') || headers.key?('content-length')

      [status, headers, [html]]
    end
  end
end
