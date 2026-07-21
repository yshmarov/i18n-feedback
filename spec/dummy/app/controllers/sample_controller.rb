# frozen_string_literal: true

class SampleController < ActionController::Base
  # `page_lang` lets a spec render the page in one language while the ambient
  # I18n.locale is something else — reproducing an app that switches locale in an
  # `around_action` (so the locale is reset by the time the widget is injected).
  def show
    @page_lang = params[:page_lang] || I18n.locale
    render inline: <<~ERB
      <!DOCTYPE html>
      <html lang="<%= @page_lang %>">
        <head><meta name="csrf-token" content="test"></head>
        <body><h1><%= t("sample.greeting") %></h1></body>
      </html>
    ERB
  end
end
