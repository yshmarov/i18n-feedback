# frozen_string_literal: true

module I18nFeedback
  class SuggestionsController < ApplicationController
    # Pending suggestions for one key/locale, shown as read-only context when the
    # proofreader reopens the popover for a string someone already flagged.
    def index
      suggestions = Suggestion
                    .where(translation_key: params[:key], locale: params[:locale])
                    .order(id: :desc)
                    .limit(20)

      render json: suggestions.map { |suggestion| suggestion_json(suggestion) }
    end

    def create
      suggestion = Suggestion.new(suggestion_params)
      attribute_author(suggestion)

      if suggestion.save
        head :created
      else
        render json: { errors: suggestion.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def attribute_author(suggestion)
      author = current_author
      return unless author

      suggestion.author_id = author.id.to_s if author.respond_to?(:id)
      suggestion.author_label = I18nFeedback.config.author_label.call(author)
    end

    def suggestion_json(suggestion)
      {
        proposed_value: suggestion.proposed_value,
        author_label: suggestion.author_label,
        created_at: suggestion.created_at.iso8601
      }
    end

    def suggestion_params
      params
        .require(:suggestion)
        .permit(:translation_key, :locale, :old_value, :proposed_value, :comment, :page_url)
    end
  end
end
