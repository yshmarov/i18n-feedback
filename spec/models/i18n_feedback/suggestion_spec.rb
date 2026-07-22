# frozen_string_literal: true

require 'rails_helper'

module I18nFeedback
  RSpec.describe Suggestion, type: :model do
    it 'requires a key, a proposed value, and a locale' do
      suggestion = described_class.new

      expect(suggestion).not_to be_valid
      expect(suggestion.errors.attribute_names).to include(:translation_key, :proposed_value, :locale)
    end

    it 'accepts a locale the app knows about' do
      suggestion = described_class.new(translation_key: 'sample.greeting', proposed_value: 'Hi', locale: 'fr')

      expect(suggestion).to be_valid
    end

    it 'rejects a locale the app does not offer' do
      suggestion = described_class.new(translation_key: 'sample.greeting', proposed_value: 'Hi', locale: 'de')

      expect(suggestion).not_to be_valid
      expect(suggestion.errors.attribute_names).to include(:locale)
    end

    it 'starts out pending' do
      suggestion = described_class.create!(translation_key: 'sample.greeting', proposed_value: 'Hi', locale: 'en')

      expect(suggestion.status).to eq('pending')
      expect(suggestion).to be_status_pending
      expect(suggestion).not_to be_status_applied
    end

    it 'exposes a predicate for each status' do
      suggestion = described_class.new(status: 'applied')

      expect(suggestion).to be_status_applied
      expect(suggestion).not_to be_status_pending
      expect(suggestion).not_to be_status_rejected
    end

    it 'refuses to be assigned an unknown status' do
      expect { described_class.new(status: 'archived') }.to raise_error(ArgumentError)
    end

    it 'caps the length of the free-text fields' do
      suggestion = described_class.new(
        translation_key: 'sample.greeting',
        locale: 'en',
        proposed_value: 'a' * 5_001,
        old_value: 'b' * 5_001,
        comment: 'c' * 2_001,
        page_url: "http://x/#{'d' * 2_001}"
      )

      expect(suggestion).not_to be_valid
      expect(suggestion.errors.attribute_names).to include(:proposed_value, :old_value, :comment, :page_url)
    end

    it 'accepts free-text fields at the maximum length' do
      suggestion = described_class.new(
        translation_key: 'sample.greeting', locale: 'en', proposed_value: 'a' * 5_000
      )

      expect(suggestion).to be_valid
    end
  end
end
