# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'I18nFeedback triage dashboard', type: :request do
  def admin!
    I18nFeedback.config.authorize_admin = ->(_request) { true }
  end

  def create_suggestion(**attrs)
    I18nFeedback::Suggestion.create!(
      { translation_key: 'sample.greeting', locale: 'en', proposed_value: 'Hi' }.merge(attrs)
    )
  end

  describe 'GET / (index)' do
    it 'is forbidden unless authorize_admin passes' do
      # Default in the test env is development-only, i.e. false here.
      get '/i18n_feedback/'

      expect(response).to have_http_status(:forbidden)
    end

    it 'lists suggestions for the selected status' do
      admin!
      create_suggestion(proposed_value: 'Pending wording')
      create_suggestion(proposed_value: 'Applied wording', status: 'applied')

      get '/i18n_feedback/', params: { status: 'pending' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Pending wording')
      expect(response.body).not_to include('Applied wording')
    end

    it 'defaults to pending and can switch to applied' do
      admin!
      create_suggestion(proposed_value: 'Applied wording', status: 'applied')

      get '/i18n_feedback/'
      expect(response.body).not_to include('Applied wording')

      get '/i18n_feedback/', params: { status: 'applied' }
      expect(response.body).to include('Applied wording')
    end

    it 'filters by locale' do
      admin!
      create_suggestion(locale: 'en', proposed_value: 'English wording')
      create_suggestion(locale: 'fr', proposed_value: 'French wording')

      get '/i18n_feedback/', params: { status: 'pending', locale: 'fr' }

      expect(response.body).to include('French wording')
      expect(response.body).not_to include('English wording')
    end

    it 'renders the locale filter with a label and a submit button (works without JS / under a strict CSP)' do
      admin!
      create_suggestion(locale: 'en')
      create_suggestion(locale: 'fr')

      get '/i18n_feedback/'

      expect(response.body).to include('<label for="i18nf-locale"')
      expect(response.body).to match(%r{<form class="filters"[^>]*>.*<button[^>]*>Filter</button>.*</form>}m)
    end
  end

  describe 'read-only: no mutation endpoints' do
    # The dashboard never writes to the host's locale files, so it deliberately
    # exposes no way to change or delete a suggestion — status is managed out of
    # band (console / a future apply feature).
    it 'does not route PATCH or DELETE for a suggestion' do
      admin!
      suggestion = create_suggestion

      patch "/i18n_feedback/suggestions/#{suggestion.id}", params: { status: 'applied' }
      expect(response).to have_http_status(:not_found)

      delete "/i18n_feedback/suggestions/#{suggestion.id}"
      expect(response).to have_http_status(:not_found)

      expect(suggestion.reload.status).to eq('pending')
    end
  end
end
