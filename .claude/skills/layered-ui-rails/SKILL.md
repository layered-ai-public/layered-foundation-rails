---
name: layered-ui-rails
description: Installs, configures, and builds with the layered-ui-rails gem - a Rails 8+ engine providing WCAG 2.2 AA compliant layout, components, and Stimulus controllers with dark/light theming. Use when adding layered-ui-rails to a Rails app, building views with its layout and helpers, styling with its CSS classes, or troubleshooting setup.
license: Apache-2.0
compatibility: Requires Ruby on Rails >= 8.0, tailwindcss-rails >= 4.0, importmap-rails >= 2.0, stimulus-rails >= 1.0
metadata:
  author: layered.ai
  version: "1.0"
  source: https://github.com/layered-ai-public/layered-ui-rails
---

# layered-ui-rails

A Rails 8+ engine providing WCAG 2.2 AA compliant design tokens, Tailwind CSS components, and Stimulus controllers for theme switching, mobile navigation, slide-out panels, modals, and tabs.

## Installation

```bash
bundle add layered-ui-rails
bin/rails generate layered:ui:install
```

The generator copies `layered_ui.css` into `app/assets/tailwind/`, adds the CSS import to `application.css`, and adds the JS import to `application.js`.

Then render the engine layout from your application layout. Place all `content_for` blocks **above** the render call - the engine layout reads them when it renders, so they must be defined first:

```erb
<% content_for :l_ui_body_class, "l-ui-body--always-show-navigation" %>

<% content_for :l_ui_navigation_items do %>
  <%= l_ui_navigation_item("Dashboard", dashboard_path) %>
  <%= l_ui_navigation_item("Users", users_path) %>
<% end %>

<%= render template: "layouts/layered_ui/application" %>
```

## Layout structure

The engine layout provides a fixed header (63px), optional sidebar navigation (240px wide), optional resizable panel (320px default), and a main content area. Dark mode is built in with a toggle and localStorage persistence.

### Content blocks

Populate layout regions with `content_for` (always above the render call):

```erb
<%# Navigation sidebar items %>
<% content_for :l_ui_navigation_items do %>
  <%= l_ui_navigation_item("Dashboard", dashboard_path) %>
  <%= l_ui_navigation_item("Users", users_path) %>
<% end %>

<%# Side panel %>
<% content_for :l_ui_panel_heading do %>
  Help
<% end %>
<% content_for :l_ui_panel_body do %>
  <p>Panel content here.</p>
<% end %>

<%# Inject into <head> (e.g. per-tenant theming) %>
<% content_for :l_ui_head do %>
  <style nonce="<%= content_security_policy_nonce %>">
    :root { --accent: oklch(0.58 0.19 255); }
  </style>
<% end %>

<%# Add CSS classes to <body> %>
<% content_for :l_ui_body_class do %>
  l-ui-body--always-show-navigation
<% end %>

<%# Override logos %>
<% content_for :l_ui_logo_light do %>
  <%= image_tag "my_logo.svg", alt: "", class: "l-ui-header__logo l-ui-header__logo--light" %>
<% end %>
<% content_for :l_ui_logo_dark do %>
  <%= image_tag "my_logo_dark.svg", alt: "", class: "l-ui-header__logo l-ui-header__logo--dark" %>
<% end %>
```

Body class modifiers:
- `l-ui-body--always-show-navigation` - pins navigation as a sidebar on desktop
- `l-ui-body--hide-header` - hides the header and collapses its space

### Controller instance variables

```ruby
@page_title = "Users"                    # Sets <title>
@page_description = "Manage users"       # Sets <meta name="description">
@l_ui_icon_light_url = url               # Override favicon (light)
@l_ui_icon_dark_url = url                # Override favicon (dark)
@l_ui_apple_touch_icon_url = url         # Override apple touch icon
@l_ui_panel_icon_light_url = url         # Override panel button icon (light)
@l_ui_panel_icon_dark_url = url          # Override panel button icon (dark)
```

## View helpers

All helpers use the `l_ui_` prefix and are available in all views automatically. See `references/HELPERS.md` for full signatures and examples.

Quick reference:

| Helper | Purpose |
|---|---|
| `l_ui_navigation_item(label, path, active: nil, &block)` | Sidebar nav link with optional nesting |
| `l_ui_breadcrumbs(&block)` | Breadcrumb nav wrapper |
| `l_ui_breadcrumb_item(label, path = nil)` | Individual breadcrumb |
| `l_ui_title_bar(title:, breadcrumbs: [], actions: nil, &block)` | Responsive page title bar with breadcrumbs and actions |
| `l_ui_pagy(pagy)` | Styled pagination (requires pagy gem) |
| `l_ui_search_form(query, url:, fields:, ...)` | Search form (requires ransack gem) |
| `l_ui_sort_link(query, attribute, label = nil, ...)` | Sortable table header (requires ransack gem) |
| `l_ui_table(records, columns:, caption:, ...)` | Styled accessible data table with optional sort and actions |
| `l_ui_form(record, fields:, url:, method:)` | Complete form with fields, error summary, and submit |
| `l_ui_normalise_field(record, config)` | Normalise a raw field config hash into canonical form |
| `l_ui_user_signed_in?` | Check if user is authenticated |
| `l_ui_current_user` | Current user object |

## CSS classes

All classes use the `l-ui-` prefix with BEM naming. Use these in host app views rather than raw Tailwind utilities. See `references/CSS.md` for the full catalogue.

Key components:

| Component | Key classes |
|---|---|
| Page layout | `.l-ui-page`, `--with-navigation`, `--vertically-centered`, `--width-constrained` |
| Buttons | `.l-ui-button`, `--primary`, `--outline`, `--outline-danger`, `--full`, `--icon` |
| Surfaces | `.l-ui-surface`, `--active`, `--sm`, `--collapsible` |
| Forms | `.l-ui-form`, `.l-ui-form__group`, `.l-ui-form__field`, `.l-ui-label`, `.l-ui-select` |
| Tables | `.l-ui-table`, `.l-ui-table__header`, `.l-ui-table__cell`, `--primary`, `--action` |
| Badges | `.l-ui-badge`, `--rounded`, `--default`, `--success`, `--warning`, `--danger` |
| Notices | `.l-ui-notice--success`, `--warning`, `--error` |
| Tabs | `.l-ui-tabs__list`, `.l-ui-tabs__tab`, `--active` |
| Modal | `.l-ui-modal`, `.l-ui-modal__header`, `.l-ui-modal__body` |

## Stimulus controllers

All controllers use the `l-ui--` namespace and are auto-registered via importmap.

| Controller | Identifier | Purpose |
|---|---|---|
| Theme | `l-ui--theme` | Dark/light mode toggle with localStorage |
| Navigation | `l-ui--navigation` | Responsive sidebar with backdrop |
| Panel | `l-ui--panel` | Resizable side panel (Cmd/Ctrl+I toggle) |
| Panel button | `l-ui--panel-button` | Draggable floating action button |
| Panel resize | `l-ui--panel-resize` | Panel width drag handle |
| Modal | `l-ui--modal` | Native `<dialog>` with focus trap |
| Tabs | `l-ui--tabs` | Accessible tabbed interface |
| Search form | `l-ui--search-form` | Multi-scope search with Turbo support and pagination param preservation |

## Theming

Override CSS custom properties after the engine import. Values are full CSS colors - `oklch()` is recommended for perceptually uniform mixing and consistent contrast, but `#hex`, `rgb()`, and keywords also work. A converter such as https://oklch.com/ can help translate from hex/rgb.

```css
@import "./layered_ui";

:root {
  --accent: oklch(0.58 0.19 255);
  --accent-foreground: oklch(1 0 0);
}
.dark {
  --accent: oklch(0.72 0.14 255);
}
```

Key tokens: `--accent`, `--accent-foreground`, `--background`, `--foreground`, `--foreground-muted`, `--border`, `--border-control`, `--surface`, `--surface-highlighted`, `--danger`, `--header-height`.

## Asset overrides

Place files in `app/assets/images/layered_ui/` to replace engine defaults:

`logo_light.svg`, `logo_dark.svg`, `icon_light.svg`, `icon_dark.svg`, `apple_touch_icon.png`.

The panel toggle button uses an inline SVG that inherits `currentColor`. Recolor it by overriding the `--button-primary-icon` Tier 2 token, or replace the image by setting both `@l_ui_panel_icon_light_url` and `@l_ui_panel_icon_dark_url` (per-request).

## Optional integrations

- **Devise** - auto-detected. Provides styled auth views, header login/register buttons, sidebar user info and logout. Setup: `bundle add devise`, run `devise:install` and `devise User` generators, add `devise_for :users` to routes. Configure `Layered::Ui.current_user_method` if not using `:current_user`. Helpers: `l_ui_devise_installed?`, `l_ui_user_signed_in?`.
- **Pagy** - auto-detected. Use `l_ui_pagy(@pagy)` for styled pagination.
- **Ransack** - auto-detected. Use `l_ui_search_form` and `l_ui_sort_link` for styled search and sortable tables.

## Configuration

```ruby
# config/initializers/layered_ui.rb
Layered::Ui.current_user_method = :current_member  # default: :current_user
```

## Common issues

- **Tailwind classes not generated** - The host app's Tailwind build only sees classes in the host app's templates. Use `l-ui-` classes (which are in the copied CSS) rather than raw Tailwind utilities when styling engine-provided patterns.
- **Missing styles** - Ensure `@import "./layered_ui";` is in `app/assets/tailwind/application.css`.
- **Missing JS controllers** - Ensure `import "layered_ui"` is in `app/javascript/application.js`.

## Further reference

- `references/HELPERS.md` - full helper signatures and examples
- `references/CSS.md` - complete CSS class catalogue
- `references/CONTROLLERS.md` - Stimulus controller targets, actions, and usage patterns
- Live demo: https://layered-ui-rails.layered.ai
