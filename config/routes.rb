# frozen_string_literal: true

I18nFeedback::Engine.routes.draw do
  resources :suggestions, only: %i[index create]
end
