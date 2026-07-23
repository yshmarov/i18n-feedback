# frozen_string_literal: true

I18nFeedback::Engine.routes.draw do
  # index/update/destroy are the admin triage dashboard; create + the `context`
  # collection route are the widget's public API (see SuggestionsController).
  resources :suggestions, only: %i[index create update destroy] do
    get :context, on: :collection
  end

  root to: 'suggestions#index'
end
