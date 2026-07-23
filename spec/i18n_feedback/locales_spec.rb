# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

# Guards the bundled widget/UI translations: every shipped locale must carry the
# exact same key set as English, so no language is ever missing a label (or left
# with a stale extra one) after an edit.
RSpec.describe 'bundled locales' do
  locales_dir = File.expand_path('../../config/locales', __dir__)
  files = Dir["#{locales_dir}/i18n_feedback.*.yml"]

  keys_for = lambda do |file|
    data = YAML.load_file(file)
    locale = data.keys.first
    data.fetch(locale).fetch('i18n_feedback').keys.sort
  end

  expected_keys = keys_for.call(File.join(locales_dir, 'i18n_feedback.en.yml'))

  it 'ships 25+ languages besides English' do
    expect(files.size).to be >= 26
  end

  it 'includes the host-facing toggle labels in English' do
    expect(expected_keys).to include('start', 'stop')
  end

  files.each do |file|
    name = File.basename(file)

    it "#{name} carries the same keys as English" do
      expect(keys_for.call(file)).to eq(expected_keys)
    end
  end
end
