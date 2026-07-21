# Changelog

## [Unreleased]

## [0.4.0]

- Add a `config.on_submit` hook, called with each saved suggestion right after
  it's stored — notify Slack, send an email, open a ticket. Runs inline after
  save, so keep it fast or hand off to a job.

## [0.3.1]

- Fix the widget showing raw key markers (e.g. `⟦i18n_feedback.title⟧`) in its own
  popover while suggest mode was on. The key-marking backend was tagging the
  tool's own `i18n_feedback.*` strings; those are not part of the host app's
  translatable copy, so they're now always skipped — the widget never marks or
  offers to edit its own UI.
- Fix the popover not following the page's language under auto-injection. The
  widget is injected in middleware *after* the controller action, so an
  `around_action { I18n.with_locale(...) }` had already reset `I18n.locale` back
  to the default — the popover (and the saved suggestion's `locale`) came out in
  the wrong language. The locale is now read from the page's rendered
  `<html lang>` attribute and labels resolve under it explicitly.

## [0.3.0]

- Localize the widget's own UI. Every string in the pill and the suggestion
  popover now resolves through Rails I18n under the `i18n_feedback.*` scope and
  follows the app's current `I18n.locale`, so the tool speaks the same language as
  the app being proofread. Any key a host hasn't translated falls back to English
  — so nothing goes blank in a locale you haven't fully covered. Override any
  string by defining the matching key in your own locale files.
- Ship translations out of the box for 20 languages in addition to English:
  Arabic, Bengali, Chinese (Simplified), Dutch, French, German, Hindi, Indonesian,
  Italian, Japanese, Korean, Polish, Portuguese, Russian, Spanish, Thai, Turkish,
  Ukrainian, Urdu and Vietnamese.
- Render the popover right-to-left for RTL locales (Arabic, Urdu, and other RTL
  scripts), detected from the active locale's language subtag. The i18n key stays
  left-to-right, since it's a code identifier rather than prose.
- `config.pill_label` now defaults to `nil`, meaning "use the localized default".
  Setting it to a string still overrides the pill text as before.
- The widget now follows the operating system's light/dark/system appearance via
  `prefers-color-scheme`. The pill and popover render with a dark surface when the
  reviewer's system is in dark mode, with no configuration required.

## [0.2.2]

- Fix suggest mode desyncing under a nonce-based CSP on Turbo visits. The runtime
  config now rides in a `<script type="application/json">` block (data, not code)
  that the widget re-reads on every `turbo:load`, instead of an executable
  `<script>` the browser refuses to re-run when Turbo re-evaluates it with a stale
  nonce. Only the widget code carries the CSP nonce now.
- Treat `?i18n_feedback=true|false` as a one-shot command: the middleware sets the
  cookie and redirects (303) to the same URL without the parameter. The cookie is
  now the single source of truth, so the parameter no longer sticks in the address
  bar and the pill's reload can turn suggest mode off.
- Let a host's own toggle link work while suggest mode is active. Suggest mode
  freezes navigation so a stray click can't leave the page mid-proofread, but that
  also froze a `?i18n_feedback=false` link in your own nav — so the only way out
  was the pill. Links carrying the toggle parameter are now exempt from the freeze.

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
