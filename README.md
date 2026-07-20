# i18n_feedback

In-context translation proofreading for Rails.

`i18n_feedback` renders every translated string alongside its i18n key in the
environments you choose, lets a reviewer click any string in the running app and
suggest a better wording, and stores those suggestions for a developer to apply.
It is meant for development and staging, never production.

- **Zero UI dependencies.** The widget is plain JavaScript and styles itself. No
  Tailwind, no daisyUI, no Stimulus, no importmap, no build step.
- **Zero layout changes.** The widget is injected into HTML responses
  automatically (opt out and place it yourself if you prefer).
- **Pluggable gating and attribution.** You decide which environments and which
  users see the tool, and how a suggestion is attributed.

## How it works

1. In an enabled environment, the I18n backend appends a hidden `⟦some.key⟧`
   marker to each translated string. Markers are only emitted while a reviewer
   has the tool switched on (a cookie), so pages are clean by default.
2. The browser widget strips every marker out of the DOM on load and remembers
   which key produced each piece of text.
3. Clicking a string opens a popover showing the current text, any pending
   suggestions, and a field to propose a new wording.
4. Suggestions are `POST`ed to the mounted engine and stored in the
   `i18n_feedback_suggestions` table for you to review and apply.

## Requirements

- Ruby >= 3.2
- Rails >= 7.1

## Installation

Add the gem:

```ruby
# Gemfile
gem "i18n_feedback"
```

```bash
bundle install
bin/rails generate i18n_feedback:install
bin/rails db:migrate
```

The generator:

- writes `config/initializers/i18n_feedback.rb`,
- creates the `i18n_feedback_suggestions` migration,
- mounts the engine in `config/routes.rb`:

  ```ruby
  mount I18nFeedback::Engine => "/i18n_feedback"
  ```

Boot the app in development and look for the **“Suggest edits”** pill in the
bottom-left corner. Click it to turn on suggest mode, then click any text to
propose a fix. Press `Esc` (or the pill) to exit.

> The widget reads the CSRF token from `<meta name="csrf-token">`, which
> `csrf_meta_tags` in your layout already provides in a standard Rails app.

## Configuration

Everything is optional; the defaults work out of the box in development.

```ruby
# config/initializers/i18n_feedback.rb
I18nFeedback.configure do |config|
  # Environments the tool is active in.
  config.enabled_environments = %w[development staging]

  # Extra per-request gate. Return false to hide the tool. Receives the request.
  config.enabled = ->(request) { true }

  # Attribute a suggestion to a user (optional). Return an object responding to
  # #id, or nil. Receives the request.
  config.current_user = ->(request) { nil }

  # Label shown for the author in the "already suggested" list.
  config.author_label = ->(user) { user.try(:email) }

  # Inject the widget automatically. Set false to place it yourself.
  config.auto_inject = true

  # Show the floating "Suggest edits" pill. Set false to drive suggest mode from
  # your own link instead (see below).
  config.show_pill = true

  # Query parameter that toggles suggest mode.
  config.toggle_param = "i18n_feedback"

  # Keep in sync with the `mount` in config/routes.rb.
  config.mount_path = "/i18n_feedback"
end
```

### Toggling suggest mode from your own link

Prefer a menu item over the floating pill? Hide the pill and link to the toggle
parameter from anywhere in your UI:

```ruby
config.show_pill = false
```

```erb
<%= link_to "Proofread translations", "?i18n_feedback=true" %>
```

`?i18n_feedback=true` turns suggest mode on and `?i18n_feedback=false` turns it
off. The choice is remembered in a cookie, so the rest of the app stays in
suggest mode without the parameter; `Esc` also exits.

### Gating examples

```ruby
# Only signed-in staff (however your app resolves that):
config.enabled = ->(request) { request.env["warden"]&.user&.staff? }

# Behind a feature flag:
config.enabled = ->(request) { Flipper.enabled?(:i18n_feedback) }
```

### Placing the widget yourself

Set `config.auto_inject = false` and drop the helper at the end of your layout:

```erb
<%= i18n_feedback_tag %>
```

It renders nothing unless the tool is available for the request.

## Reviewing suggestions

Suggestions are ordinary records:

```ruby
I18nFeedback::Suggestion.order(created_at: :desc).each do |s|
  puts "#{s.locale} #{s.translation_key}: #{s.old_value.inspect} -> #{s.proposed_value.inspect}"
end
```

Each row stores `translation_key`, `locale`, `old_value`, `proposed_value`,
`comment`, `page_url`, and optional `author_id` / `author_label`.

## Security

- The tool is gated **on the server** for every marker, endpoint, and injection.
  Setting the cookie by hand does nothing outside an enabled environment where
  `config.enabled` returns true.
- Format and lookup namespaces (`number.*`, `date.*`, `*_html` formats, etc.) are
  never marked, so currency and date formatting are unaffected.

## Development

```bash
bin/setup        # or: bundle install
bundle exec rspec
```

Tests run against a dummy Rails app under `spec/dummy`.

## License

Released under the [MIT License](MIT-LICENSE).
