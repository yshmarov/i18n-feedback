# Changelog

## [Unreleased]

## [0.1.0]

- Initial release.
- In-context i18n key markers, gated to configured environments and toggled per
  request by the widget.
- Self-contained browser widget (no CSS or JS framework required) with a suggest
  pill and a per-string suggestion popover.
- `I18nFeedback::Suggestion` model and mountable engine endpoints for listing and
  creating suggestions.
- `i18n_feedback:install` generator (initializer, migration, engine mount).
