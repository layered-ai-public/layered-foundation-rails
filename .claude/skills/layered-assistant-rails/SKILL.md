---
name: layered-assistant-rails
description: Installs, configures, and builds with the layered-assistant-rails gem - a Rails 8+ engine providing AI assistant UI, conversations, providers, models, personas and skills, with a side-panel chat. Use when adding layered-assistant-rails to a Rails app, mounting the engine, configuring authorization and scoping, embedding the assistant panel, or troubleshooting setup.
license: Apache-2.0
compatibility: Requires Ruby on Rails >= 8.0, Ruby >= 3.2, layered-ui-rails >= 0.4, importmap-rails >= 2.0, stimulus-rails >= 1.0, turbo-rails
metadata:
  author: layered.ai
  version: "1.0"
  source: https://github.com/layered-ai-public/layered-assistant-rails
---

# layered-assistant-rails

A Rails 8+ engine providing an AI assistant: conversations, messages with streaming, configurable providers (Anthropic, OpenAI), models, personas, skills, and a side-panel chat that drops into any layered-ui-rails layout.

It builds on `layered-ui-rails` for layout, components, and theming. Install that gem first (or let this generator install it for you).

## Installation

```bash
bundle add layered-assistant-rails
bin/rails generate layered:assistant:install
bin/rails db:migrate
```

The install generator:

1. Verifies `layered-ui-rails` is installed - invokes its installer if not.
2. Adds `import "layered_assistant"` to `app/javascript/application.js` (after the `layered_ui` import).
3. Creates `config/initializers/layered_assistant.rb` with example `authorize` and `scope` blocks.
4. Mounts the engine at `/layered/assistant` in `config/routes.rb`.
5. Copies migrations into the host app via the `layered:assistant:migrations` generator.

After installation, configure the initializer (see below) - **routes return 403 until an `authorize` block is set**. Then visit `/layered/assistant` to set up providers, models, personas, skills and assistants.

## Authorization

All non-public engine routes are gated by an `authorize` block. The block runs in controller context, so you have access to `current_user`, `request`, `redirect_to`, `head`, `main_app`, etc.

```ruby
# config/initializers/layered_assistant.rb

# Require sign-in (Devise):
Layered::Assistant.authorize do
  redirect_to main_app.new_user_session_path unless user_signed_in?
end

# Restrict to admins:
Layered::Assistant.authorize do
  head :forbidden unless current_user&.admin?
end

# Allow all (no-op):
Layered::Assistant.authorize do
end
```

Until configured, every request returns 403. Public routes under `/layered/assistant/public/...` are exempt - use these to expose specific assistants to anonymous visitors.

## Scoping (multi-tenant ownership)

Engine models with a polymorphic `owner` association (assistants, personas, providers, models, skills, conversations) can be scoped per request. The block receives the model class and returns an `ActiveRecord::Relation`:

```ruby
Layered::Assistant.scope do |model_class|
  model_class.where(owner: current_user)
end
```

Scope only conversations, leave the rest unscoped:

```ruby
Layered::Assistant.scope do |model_class|
  if model_class == Layered::Assistant::Conversation
    model_class.where(owner: current_user)
  else
    model_class.all
  end
end
```

Ownership is enforced **at the controller layer via `scoped()`**, not via model validations. Out-of-scope IDs return 404.

## Optional settings

```ruby
Layered::Assistant.log_errors = true             # log API errors to stdout
Layered::Assistant.api_request_timeout = 210     # total streaming API timeout (seconds)
Layered::Assistant.skip_db_encryption = true     # dev/test only - skip encryption on Provider#secret
```

`Provider#secret` is encrypted with Rails encrypted attributes, so the host app must have `bin/rails db:encryption:init` keys configured (or set `skip_db_encryption = true` for dev/test).

## Mounting the assistant panel

The engine ships a side-panel chat that plugs into the `layered-ui-rails` panel slot. Use `PanelHelper` inside your layout's `content_for` blocks (always **above** the layout render call):

```erb
<% content_for :l_ui_panel_heading do %>
  <%= layered_assistant_panel_header %>
<% end %>

<% content_for :l_ui_panel_body do %>
  <%= layered_assistant_panel_body %>
<% end %>

<%= render template: "layouts/layered_ui/application" %>
```

The body lazy-loads the conversation list from `panel_conversations_path` via a Turbo Frame.

For a public (unauthenticated) panel scoped to one assistant:

```erb
<% content_for :l_ui_panel_body do %>
  <%= layered_assistant_public_panel_body(assistant: @assistant) %>
<% end %>
```

## View helpers

| Helper | Purpose |
|---|---|
| `layered_assistant_panel_header(**opts, &block)` | Turbo frame for the panel header |
| `layered_assistant_panel_body(**opts)` | Turbo frame that loads the authenticated panel conversations |
| `layered_assistant_public_panel_body(assistant:, **opts)` | Turbo frame for an unauthenticated single-assistant panel |
| `l_assistant_accessible?` | Returns true if the current request would pass the `authorize` block - useful for hiding the panel from unauthorised users |

Example - only render the panel for users who can access it:

```erb
<% if l_assistant_accessible? %>
  <% content_for :l_ui_panel_heading do %>
    <%= layered_assistant_panel_header %>
  <% end %>
  <% content_for :l_ui_panel_body do %>
    <%= layered_assistant_panel_body %>
  <% end %>
<% end %>
```

## Models

All under `Layered::Assistant::*`, tables prefixed `layered_assistant_`. Inherit from `Layered::Assistant::ApplicationRecord`.

| Model | Purpose |
|---|---|
| `Provider` | API provider config (Anthropic, OpenAI). Holds the encrypted `secret` (API key) |
| `Model` | A specific model offered by a `Provider` (e.g. `claude-opus-4-7`) |
| `Persona` | Reusable system prompt / character |
| `Skill` | A capability that can be attached to assistants |
| `Assistant` | A configured assistant: model + persona + skills |
| `AssistantSkill` | Join between assistant and skill |
| `Conversation` | A chat session with an assistant, owned polymorphically |
| `Message` | A single message in a conversation; supports streaming |

Enums are stored as **strings**, not integers.

## Routes

Mounted at `/layered/assistant` by default. Top-level resources: `personas`, `skills`, `assistants` (with nested `conversations`), `providers` (with nested `models`), `conversations` (with nested `messages` and a `stop` member route).

The engine also exposes:

- `panel/conversations` and `panel/conversations/:id/messages` - the authenticated side-panel API
- `public/assistants`, `public/conversations`, `public/panel/conversations` - unauthenticated entry points for embedding a single assistant on a public page

Use `layered_assistant.<route>_path` from the host app, or `main_app.<route>_path` from inside engine views.

## JavaScript

Stimulus controllers are registered automatically via importmap once `import "layered_assistant"` is in `application.js`:

| Identifier | Purpose |
|---|---|
| `composer` | Message composer (textarea autosize, submit-on-enter) |
| `messages` | Message list rendering and scroll behaviour |
| `panel` | Assistant side-panel state |
| `panel-nav` | Conversation list navigation inside the panel |
| `conversation-select` | Conversation picker |
| `provider-template` | Provider form prefill from a template |

`message_streaming.js` wires SSE streaming for assistant replies.

## Styling

The engine renders inside `layered-ui-rails` layouts and uses only `l-ui-` classes - no host-app Tailwind utilities are required, and **no engine-only Tailwind classes leak into views** (the host's Tailwind build does not scan engine view files). If you customise the look, theme via `layered-ui-rails` CSS custom properties.

## Conventions

- **Locale**: en-GB unless a technical standard dictates otherwise.
- **Ownership**: enforce via `scoped()` in controllers, not model validations.
- **No bundler**: importmap only.
- **Accessibility**: WCAG 2.2 AA - tables include `<caption>`, `scope="col"`/`scope="row"`, etc.

## Common issues

- **All routes return 403** - no `authorize` block is configured. Edit `config/initializers/layered_assistant.rb`.
- **Provider creation fails with encryption error** - run `bin/rails db:encryption:init` and add the keys to credentials, or set `Layered::Assistant.skip_db_encryption = true` for dev/test.
- **Panel body never loads** - `turbo-rails` must be installed and `layered-ui-rails` must be mounted in the layout. Check `import "@hotwired/turbo-rails"` is present.
- **`layered_assistant` JS controllers missing** - ensure `import "layered_assistant"` is in `app/javascript/application.js` (added by the install generator, after the `layered_ui` import).
- **Cross-tenant records visible** - configure `Layered::Assistant.scope` to filter by `owner`.

## Further reference

- Repository: https://github.com/layered-ai-public/layered-assistant-rails
- Companion gem: `layered-ui-rails` - layout, components, helpers (skill `layered-ui-rails`)
