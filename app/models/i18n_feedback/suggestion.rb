# frozen_string_literal: true

module I18nFeedback
  # A proposed wording for one translation key in one locale. Author attribution
  # is optional and stored as loose fields (no foreign key to the host's user
  # table) so the model is portable across apps with different user models.
  class Suggestion < ApplicationRecord
    # Lifecycle of a proposed wording: a fresh suggestion is `pending` until a
    # developer applies it to the locale files or rejects it. String-backed so
    # the column stays human-readable; prefixed so the generated methods read as
    # `status_pending?` / `Suggestion.status_applied` and never clash.
    STATUSES = %w[pending applied rejected].freeze

    enum :status, STATUSES.index_by(&:itself), prefix: :status, default: :pending

    validates :translation_key, presence: true, length: { maximum: 500 }
    validates :proposed_value, presence: true, length: { maximum: 5_000 }
    validates :old_value, length: { maximum: 5_000 }
    validates :comment, length: { maximum: 2_000 }
    validates :page_url, length: { maximum: 2_000 }
    validates :locale,
              presence: true,
              inclusion: { in: ->(_) { I18nFeedback.config.available_locales.call.map(&:to_s) } }

    scope :newest_first, -> { order(id: :desc) }
  end
end
