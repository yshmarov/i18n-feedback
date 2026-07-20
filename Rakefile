# frozen_string_literal: true

require 'bundler/setup'

APP_RAKEFILE = File.expand_path('spec/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake' if File.exist?(APP_RAKEFILE)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task default: :spec
