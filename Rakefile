# frozen_string_literal: true

require 'bundler/setup'
# Defines build/install/release — `rake release` is what the trusted-publishing
# workflow (.github/workflows/release.yml) runs to push the gem to RubyGems.
require 'bundler/gem_tasks'

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake' if File.exist?(APP_RAKEFILE)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
