# frozen_string_literal: true

require 'rails_helper'

RSpec.describe I18nFeedback do
  let(:request) { instance_double(Rack::Request) }

  describe '.available?' do
    it 'is true in an enabled environment when the gate passes' do
      described_class.config.enabled = ->(_request) { true }

      expect(described_class.available?(request)).to be(true)
    end

    it 'is false when the per-request gate rejects it' do
      described_class.config.enabled = ->(_request) { false }

      expect(described_class.available?(request)).to be(false)
    end

    it 'is false outside the enabled environments' do
      described_class.config.enabled_environments = %w[staging]

      expect(described_class.available?(request)).to be(false)
    end
  end
end
