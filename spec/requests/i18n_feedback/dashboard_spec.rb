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
  end

  describe 'PATCH /suggestions/:id' do
    it 'changes the status' do
      admin!
      suggestion = create_suggestion

      patch "/i18n_feedback/suggestions/#{suggestion.id}", params: { status: 'applied' }

      expect(response).to have_http_status(:see_other)
      expect(suggestion.reload.status).to eq('applied')
    end

    it 'ignores an unknown status instead of erroring' do
      admin!
      suggestion = create_suggestion

      patch "/i18n_feedback/suggestions/#{suggestion.id}", params: { status: 'archived' }

      expect(response).to have_http_status(:see_other)
      expect(suggestion.reload.status).to eq('pending')
    end

    it 'is forbidden without admin' do
      suggestion = create_suggestion

      patch "/i18n_feedback/suggestions/#{suggestion.id}", params: { status: 'applied' }

      expect(response).to have_http_status(:forbidden)
      expect(suggestion.reload.status).to eq('pending')
    end
  end

  describe 'DELETE /suggestions/:id' do
    it 'deletes the suggestion' do
      admin!
      suggestion = create_suggestion

      expect do
        delete "/i18n_feedback/suggestions/#{suggestion.id}"
      end.to change(I18nFeedback::Suggestion, :count).by(-1)

      expect(response).to have_http_status(:see_other)
    end

    it 'is forbidden without admin' do
      suggestion = create_suggestion

      expect do
        delete "/i18n_feedback/suggestions/#{suggestion.id}"
      end.not_to change(I18nFeedback::Suggestion, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
