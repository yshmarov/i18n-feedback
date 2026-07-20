# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'

module I18nFeedback
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      desc 'Installs i18n_feedback: config initializer, migration, and engine mount.'

      def create_initializer
        copy_file 'initializer.rb', 'config/initializers/i18n_feedback.rb'
      end

      def create_suggestions_migration
        migration_template 'create_i18n_feedback_suggestions.rb.tt',
                           'db/migrate/create_i18n_feedback_suggestions.rb'
      end

      def mount_engine
        route %(mount I18nFeedback::Engine => "/i18n_feedback")
      end

      def post_install
        say "\ni18n_feedback installed. Run `rails db:migrate`, then boot in development", :green
        say "and look for the “Suggest edits” pill in the bottom-left corner.\n"
      end

      private

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
