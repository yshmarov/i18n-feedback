# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require_relative 'spec_helper'
require_relative 'dummy/config/environment'
require 'rspec/rails'

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :i18n_feedback_suggestions, force: true do |t|
    t.string :translation_key, null: false
    t.string :locale, null: false
    t.text :old_value
    t.text :proposed_value, null: false
    t.text :comment
    t.string :page_url
    t.string :author_id
    t.string :author_label
    t.timestamps
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!

  # Start every example from a fresh config (enabled in the test environment), so
  # a gating stub in one example can never leak into another under random order.
  config.around do |example|
    fresh = I18nFeedback::Configuration.new
    fresh.enabled_environments = %w[test]
    I18nFeedback.instance_variable_set(:@config, fresh)
    example.run
  end
end
