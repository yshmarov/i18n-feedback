# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'I18nFeedback::Suggestions', type: :request do
  let(:valid_params) do
    {
      suggestion: {
        translation_key: 'sample.greeting',
        locale: 'en',
        old_value: 'Hello',
        proposed_value: 'Hi there',
        comment: 'friendlier',
        page_url: 'http://example.test/sample'
      }
    }
  end

  describe 'POST /i18n_feedback/suggestions' do
    it 'stores the suggestion' do
      expect do
        post '/i18n_feedback/suggestions', params: valid_params
      end.to change(I18nFeedback::Suggestion, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(I18nFeedback::Suggestion.last.proposed_value).to eq('Hi there')
    end

    it 'rejects an invalid suggestion' do
      post '/i18n_feedback/suggestions',
           params: { suggestion: { translation_key: '', locale: 'en', proposed_value: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'attributes the suggestion via the configured resolver' do
      author = Struct.new(:id, :email).new(42, 'translator@example.test')
      I18nFeedback.config.current_user = ->(_request) { author }

      post '/i18n_feedback/suggestions', params: valid_params

      suggestion = I18nFeedback::Suggestion.last
      expect(suggestion.author_id).to eq('42')
      expect(suggestion.author_label).to eq('translator@example.test')
    end

    it 'is forbidden when the tool is not available for the request' do
      I18nFeedback.config.enabled = ->(_request) { false }

      post '/i18n_feedback/suggestions', params: valid_params

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /i18n_feedback/suggestions' do
    it 'lists pending suggestions for a key and locale' do
      I18nFeedback::Suggestion.create!(translation_key: 'sample.greeting', locale: 'en', proposed_value: 'Hi')
      I18nFeedback::Suggestion.create!(translation_key: 'other.key', locale: 'en', proposed_value: 'Nope')

      get '/i18n_feedback/suggestions', params: { key: 'sample.greeting', locale: 'en' }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.size).to eq(1)
      expect(body.first['proposed_value']).to eq('Hi')
    end
  end
end
