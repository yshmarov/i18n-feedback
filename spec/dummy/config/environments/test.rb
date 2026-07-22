# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr

  # A real (in-process) cache so the per-IP rate limiter actually counts in
  # request specs; the suite clears it between examples for isolation.
  config.cache_store = :memory_store
end
