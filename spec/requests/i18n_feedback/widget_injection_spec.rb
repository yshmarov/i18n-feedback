# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'widget injection and key marking', type: :request do
  it 'injects the widget into HTML responses when the tool is available' do
    get '/sample'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('window.__i18nFeedback')
    expect(response.body).to include('data-i18n-feedback-widget')
  end

  it 'does not emit key markers without the suggest-mode cookie' do
    get '/sample'

    expect(response.body).not_to include("#{I18nFeedback::Marking::LEFT}sample.greeting")
  end

  it 'emits key markers when the suggest-mode cookie is set' do
    get '/sample', headers: { 'HTTP_COOKIE' => 'i18n_feedback=1' }

    expect(response.body).to include("#{I18nFeedback::Marking::LEFT}sample.greeting#{I18nFeedback::Marking::RIGHT}")
  end

  it 'injects nothing when the tool is unavailable' do
    I18nFeedback.config.enabled = ->(_request) { false }

    get '/sample'

    expect(response.body).not_to include('window.__i18nFeedback')
  end
end
