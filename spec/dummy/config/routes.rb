# frozen_string_literal: true

Rails.application.routes.draw do
  mount I18nFeedback::Engine => "/i18n_feedback"
  get "sample", to: "sample#show"
end
