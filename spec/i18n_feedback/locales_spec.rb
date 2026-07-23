# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

# Guards the bundled translations. The widget/UI keys must be present in every
# shipped locale, so no language is ever missing a label after an edit. The
# dashboard keys (`dashboard`, `statuses`) are an admin-facing surface shipped in
# English only — rendered through I18n with English fallbacks — so they live in
# en.yml alone and are excluded from the per-locale parity check.
RSpec.describe 'bundled locales' do
  locales_dir = File.expand_path('../../config/locales', __dir__)
  files = Dir["#{locales_dir}/i18n_feedback.*.yml"]
  admin_only_keys = %w[dashboard statuses]

  keys_for = lambda do |file|
    data = YAML.load_file(file)
    locale = data.keys.first
    data.fetch(locale).fetch('i18n_feedback').keys.map(&:to_s)
  end

  widget_keys = lambda do |file|
    (keys_for.call(file) - admin_only_keys).sort
  end

  en_file = File.join(locales_dir, 'i18n_feedback.en.yml')
  expected_widget_keys = widget_keys.call(en_file)

  it 'ships 25+ languages besides English' do
    expect(files.size).to be >= 26
  end

  it 'includes the host-facing toggle labels in English' do
    expect(expected_widget_keys).to include('start', 'stop')
  end

  it 'ships the dashboard strings in English' do
    en = YAML.load_file(en_file)['en']['i18n_feedback']
    expect(en['statuses'].keys).to contain_exactly('pending', 'applied', 'rejected')
    expect(en['dashboard']).to include('title', 'apply', 'reject', 'delete', 'empty')
  end

  files.each do |file|
    name = File.basename(file)

    it "#{name} carries the same widget keys as English" do
      expect(widget_keys.call(file)).to eq(expected_widget_keys)
    end
  end
end
