# Changelog

## [Unreleased]

## [0.2.1]

- Keep the suggest pill and active-mode highlighting working across Turbo Drive
  navigations. Turbo replaces `<body>` on each visit, which removed the pill; the
  widget now re-runs its per-page setup on `turbo:load` instead of only on the
  initial load, so it no longer requires a hard reload.

## [0.2.0]

- Stamp the injected widget scripts with the request's Content-Security-Policy
  nonce when one is present, so the tool works under a nonce-based CSP (including
  `strict-dynamic`). No-op for apps without a CSP nonce.

## [0.1.0]

- Initial release.
- In-context i18n key markers, gated to configured environments and toggled per
  request by the widget.
- Self-contained browser widget (no CSS or JS framework required) with a suggest
  pill and a per-string suggestion popover. The copy cursor and hover outline
  appear only on the strings that resolve to a key.
- Optional floating pill (`config.show_pill`) and a URL toggle
  (`?i18n_feedback=true` / `false`, remembered in a cookie) so suggest mode can
  be triggered from a host-provided link instead.
- `I18nFeedback::Suggestion` model and mountable engine endpoints for listing and
  creating suggestions.
- `i18n_feedback:install` generator (initializer, migration, engine mount).
