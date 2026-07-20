# frozen_string_literal: true

module I18nFeedback
  # A proposed wording for one translation key in one locale. Author attribution
  # is optional and stored as loose fields (no foreign key to the host's user
  # table) so the model is portable across apps with different user models.
  class Suggestion < ApplicationRecord
    validates :translation_key, presence: true
    validates :proposed_value, presence: true
    validates :locale,
              presence: true,
              inclusion: { in: ->(_) { I18nFeedback.config.available_locales.call.map(&:to_s) } }
  end
end
