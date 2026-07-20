# frozen_string_literal: true

require_relative 'lib/i18n_feedback/version'

Gem::Specification.new do |spec|
  spec.name = 'i18n_feedback'
  spec.version = I18nFeedback::VERSION
  spec.authors = ['Yaroslav Shmarov']
  spec.email = ['yaroslav.shmarov@clickfunnels.com']

  spec.summary = 'In-context i18n proofreading for Rails: click any translated string and suggest a fix.'
  spec.description = <<~DESC
    A mountable Rails engine that renders each translation alongside its i18n key
    in development and staging, lets reviewers click any string in the running app
    and propose a better wording, and stores those suggestions for a developer to
    apply. Framework-agnostic: no CSS or JS framework required.
  DESC
  spec.homepage = 'https://github.com/yshmarov/i18n-feedback'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    'app/**/*',
    'config/**/*',
    'lib/**/*',
    'MIT-LICENSE',
    'Rakefile',
    'README.md',
    'CHANGELOG.md'
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 7.1'
end
