# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'widget injection and key marking', type: :request do
  it 'injects the widget into HTML responses when the tool is available' do
    get '/sample'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-i18n-feedback-config')
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

    expect(response.body).not_to include('data-i18n-feedback-widget')
  end

  it 'turns suggest mode on via the toggle parameter, then redirects to the clean URL' do
    get '/sample', params: { i18n_feedback: 'true' }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to eq('/sample')
    expect(response.cookies['i18n_feedback']).to eq('1')
  end

  it 'turns suggest mode off via the toggle parameter, then redirects to the clean URL' do
    get '/sample', params: { i18n_feedback: 'false' }, headers: { 'HTTP_COOKIE' => 'i18n_feedback=1' }

    expect(response).to have_http_status(:see_other)
    expect(response.location).to eq('/sample')
    expect(response.cookies['i18n_feedback']).to be_blank
  end

  it 'injects localized UI labels into the config' do
    get '/sample'

    expect(response.body).to include('"labels":')
    expect(response.body).to include('"save":"Send suggestion"')
  end

  it 'follows the app locale for the widget labels using the shipped translations' do
    I18n.with_locale(:fr) { get '/sample' }

    expect(response.body).to include('"save":"Envoyer la suggestion"')
    expect(response.body).to include('"cancel":"Annuler"')
  end

  it 'lets the host override a shipped label from its own locale files' do
    # store_translations mutates the process-wide backend, so undo it afterward
    # to keep the shipped-translation example order-independent.
    I18n.backend.store_translations(:fr, i18n_feedback: { save: 'Soumettre' })
    I18n.with_locale(:fr) { get '/sample' }

    expect(response.body).to include('"save":"Soumettre"')
  ensure
    I18n.reload!
  end

  it 'omits the pill from the injected config when show_pill is false' do
    I18nFeedback.config.show_pill = false

    get '/sample'

    expect(response.body).to include('"showPill":false')
  end

  it 'stamps the widget script with the CSP nonce, leaving the JSON config (data, not code) unstamped' do
    get '/sample'

    expect(response.body).to include('<script data-i18n-feedback-widget nonce="testnonce">')
    expect(response.body).to include('<script type="application/json" data-i18n-feedback-config>')
    expect(response.body).not_to match(/data-i18n-feedback-config[^>]*nonce=/)
  end
end
