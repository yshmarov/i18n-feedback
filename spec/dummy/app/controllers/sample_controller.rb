# frozen_string_literal: true

class SampleController < ActionController::Base
  def show
    render inline: <<~ERB
      <!DOCTYPE html>
      <html>
        <head><meta name="csrf-token" content="test"></head>
        <body><h1><%= t("sample.greeting") %></h1></body>
      </html>
    ERB
  end
end
