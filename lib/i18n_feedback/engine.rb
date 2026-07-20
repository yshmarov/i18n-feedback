# frozen_string_literal: true

module I18nFeedback
  class Engine < ::Rails::Engine
    isolate_namespace I18nFeedback

    initializer 'i18n_feedback.middleware' do |app|
      app.middleware.use I18nFeedback::Middleware
    end

    # Prepend the key-marking backend once the app (and its I18n backend) is up,
    # and only in an enabled environment, so production never carries the patch.
    config.after_initialize do
      if I18nFeedback.config.environment_enabled? &&
         !I18n.backend.class.include?(I18nFeedback::Marking::Backend)
        I18n.backend.class.prepend(I18nFeedback::Marking::Backend)
      end
    end

    initializer 'i18n_feedback.helper' do
      ActiveSupport.on_load(:action_view) do
        include I18nFeedback::TagHelper
      end
    end
  end
end
