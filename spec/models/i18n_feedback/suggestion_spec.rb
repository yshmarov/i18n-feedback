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
  end
end
