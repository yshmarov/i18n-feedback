# frozen_string_literal: true

I18nFeedback::Engine.routes.draw do
  # index is the read-only admin dashboard; create + the `context` collection
  # route are the widget's public API (see SuggestionsController). There is
  # deliberately no update/destroy — the tool never mutates suggestions from the
  # UI, since it can't write to the host's locale files.
  resources :suggestions, only: %i[index create] do
    get :context, on: :collection
  end

  root to: 'suggestions#index'
end
