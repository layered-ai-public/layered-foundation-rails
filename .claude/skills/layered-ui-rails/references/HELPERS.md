# View helpers

All helpers are prefixed `l_ui_` and are available in all views automatically.

## Navigation

```ruby
l_ui_navigation_item(label, path, active: nil, match: :exact, icon: nil, icon_path: nil, icon_html: nil)
l_ui_navigation_section(heading = nil, icon: nil, icon_path: nil, icon_html: nil, collapsible: false, expanded: true, storage_key: nil, separated: false, &block)
```

`l_ui_navigation_item`:
- `label` (String) - link text
- `path` (String) - URL
- `active` (Boolean, optional) - force the active style; defaults to a match against the current request path. Does not affect `aria-current`, which is set only when `current_page?(path)` is true
- `match` (Symbol) - `:exact` (default) uses `current_page?`; `:starts_with` activates when the request path begins with `path` (use for parents whose sub-routes should keep the parent highlighted)
- `icon` (String, optional) - icon name. Resolves to the asset `layered_ui/icon_NAME.svg`. See "Icons" below for the names that ship with the gem and how to add your own. A name with no matching asset raises `Propshaft::MissingAssetError` (a 500 in dev) when the page renders, so only pass a name you know resolves
- `icon_path` (String, optional) - explicit asset path; takes precedence over `icon:`
- `icon_html` (ActiveSupport::SafeBuffer, optional) - pre-rendered icon markup for icon-font libraries (e.g. `tag.i(class: "fa-solid fa-house")`); takes precedence over `icon:` and `icon_path:`. Must be already html-safe - plain strings will be escaped. Never pass user-controlled input

`l_ui_navigation_section`:
- `heading` (String, optional) - non-clickable section heading; omit for an unlabelled group. To expose the parent route of a section, add an "Overview" item inside the block
- `icon` (String, optional) - icon name next to the heading; resolves the same way as `l_ui_navigation_item`'s `icon:` (see "Icons" below)
- `icon_path` (String, optional) - explicit asset path next to the heading; takes precedence over `icon:`
- `icon_html` (String, optional) - pre-rendered icon markup; takes precedence over `icon:` and `icon_path:`
- `collapsible` (Boolean) - when `true` and a heading is given, renders a toggle button with a chevron and wires `aria-controls` to the panel
- `expanded` (Boolean) - default open state for collapsible sections; a section that contains an active descendant always opens
- `storage_key` (String, optional) - localStorage key to persist the open/closed preference
- `separated` (Boolean) - draw a horizontal rule above the section, useful for footer-style groups
- `&block` - section body, typically `l_ui_navigation_item`s

```erb
<% content_for :l_ui_navigation_items do %>
  <%= l_ui_navigation_section do %>
    <%= l_ui_navigation_item("Home", root_path, icon: "home") %>
  <% end %>

  <%= l_ui_navigation_section("Products", collapsible: true, storage_key: "products") do %>
    <%= l_ui_navigation_item("Overview", products_path) %>
    <%= l_ui_navigation_item("Electronics", electronics_path, match: :starts_with) %>
    <%= l_ui_navigation_item("Clothing", clothing_path) %>
  <% end %>
<% end %>
```

### Icons

The `icon:` argument (on `l_ui_navigation_item` and `l_ui_navigation_section`) resolves to the asset `layered_ui/icon_NAME.svg`. There is no fallback: a name with no matching asset raises `Propshaft::MissingAssetError` and renders a 500. Only pass a name you know resolves.

Names that ship with the gem (use the bare name, e.g. `icon: "globe"`):

- General-purpose (black `currentColor` sources, recoloured for dark mode by `dark:invert` - safe to use via `icon:`): `home`, `globe`, `mail`, `github`, `discord`, `linkedin`, `x`, `youtube`
- Internal UI (engine chrome - theme toggle, nav chevrons, close buttons): `close`, `chevron_down`, `chevron_right`, `hamburger`, `sun`, `moon`, `light`, `dark`, `panel_close`. Several are CSS mask shapes or carry baked theme colours (e.g. `chevron_down` is white, `dark` fills white), so they will **not** render correctly through `icon:`. Don't use these for nav icons

To add your own, drop an SVG in the host app at `app/assets/images/layered_ui/icon_NAME.svg` and pass `icon: "NAME"`. Alternatively:

- `icon_path:` - point at any asset path directly (e.g. `icon_path: "my_icons/star.svg"`), bypassing the `layered_ui/icon_` convention
- `icon_html:` - pass pre-rendered, html-safe markup for icon-font libraries (e.g. `tag.i(class: "fa-solid fa-house")`); never pass user-controlled input

## Breadcrumbs

```ruby
l_ui_breadcrumbs(&block)
l_ui_breadcrumb_item(label, path = nil)
```

- `label` (String) - breadcrumb text
- `path` (String, optional) - URL; omit for the current page (sets `aria-current="page"`)

```erb
<%= l_ui_breadcrumbs do %>
  <%= l_ui_breadcrumb_item("Home", root_path) %>
  <%= l_ui_breadcrumb_item("Users", users_path) %>
  <%= l_ui_breadcrumb_item("Alice") %>
<% end %>
```

## Title bar

```ruby
l_ui_title_bar(title:, breadcrumbs: [], actions: nil, &block)
```

- `title` (String) - page title rendered as the `<h1>`
- `breadcrumbs` (Array, optional) - breadcrumb items as `[label, path]` arrays or `{ label:, path: }` hashes
- `actions` (String|Array, optional) - HTML-safe action content; omit when using a block
- `&block` - optional action markup, usually buttons or links

```erb
<%= l_ui_title_bar(
  title: "Users",
  breadcrumbs: [
    ["Home", root_path],
    ["Admin", admin_path]
  ]
) do %>
  <%= link_to "New user", new_user_path, class: "l-ui-button l-ui-button--primary" %>
<% end %>
```

## Pagination (requires pagy gem)

```ruby
l_ui_pagy(pagy)
```

- `pagy` (Pagy) - the pagy object from controller
- Returns `nil` if pagy is not installed or there is only one page

```erb
<%= l_ui_pagy(@pagy) %>
```

## Search form (requires ransack gem)

```ruby
l_ui_search_form(query, url: nil, fields: [], predicate: :cont, combinator: :or,
                 label: "Search", placeholder: nil, button: "Search",
                 clear: nil, turbo_frame: nil, html: {}, &block)
```

- `query` (Ransack::Search) - the `@q` object from controller
- `url` (String, required) - form action URL
- `fields` (Array<Symbol>) - fields to search (simple mode)
- `predicate` (Symbol) - ransack predicate, default `:cont`
- `combinator` (Symbol) - `:or` or `:and` for multiple fields
- `label` (String) - hidden label for the search input
- `placeholder` (String) - input placeholder
- `button` (String) - submit button text
- `clear` (String|Boolean) - clear button text; `true` for default, `false` to hide
- `turbo_frame` (String) - turbo frame to target
- `html` (Hash) - additional form HTML attributes
- `&block` - custom form markup (overrides simple mode)

Simple mode:

```erb
<%= l_ui_search_form(@q, url: users_path, fields: [:name, :email],
    placeholder: "Search users", clear: true, turbo_frame: "users") %>
```

Custom mode:

```erb
<%= l_ui_search_form(@q, url: users_path) do |f| %>
  <%= render "layered_ui/shared/search_field", form: f, field: :name_cont, label: "Name" %>
  <%= render "layered_ui/shared/search_select", form: f, field: :status_eq,
      label: "Status", options: ["Active", "Inactive"], include_blank: "Any" %>
  <%= f.submit "Search", class: "l-ui-button l-ui-button--primary" %>
<% end %>
```

## Sort link (requires ransack gem)

```ruby
l_ui_sort_link(query, attribute, label = nil, default_order: nil,
               turbo_frame: nil, html: {})
```

- `query` (Ransack::Search) - the `@q` object
- `attribute` (Symbol) - model attribute to sort by
- `label` (String, optional) - custom header text; defaults to humanised attribute name
- `default_order` (Symbol) - `:asc` or `:desc` on first click
- `turbo_frame` (String) - turbo frame target
- `html` (Hash) - additional HTML attributes

Returns a `<th>` element with sort link and ARIA sort attributes.

```erb
<table class="l-ui-table">
  <thead class="l-ui-table__header">
    <tr>
      <%= l_ui_sort_link(@q, :name) %>
      <%= l_ui_sort_link(@q, :created_at, "Joined", default_order: :desc, turbo_frame: "users") %>
    </tr>
  </thead>
</table>
```

## Table

```ruby
l_ui_table(records, columns:, caption: nil, actions: nil,
           actions_label: "Actions", query: nil, url: nil,
           turbo_frame: nil, row_id: nil)
```

- `records` (ActiveRecord::Relation or Array) - the collection to render
- `columns` (Array<Hash>) - column definitions (see below)
- `caption` (String, optional) - visually hidden table caption for accessibility
- `actions` (Proc, optional) - receives (record), returns action cell content
- `actions_label` (String) - header text for the actions column, default "Actions"
- `query` (Ransack::Search, optional) - enables sortable column headers
- `url` (String, optional) - sort link URL (passed to `l_ui_sort_link`)
- `turbo_frame` (String, optional) - turbo frame target for sort links
- `row_id` (Proc, optional) - receives (record), returns the `<tr>` id. Defaults to `dom_id(record)` for records that respond to `to_key` (ActiveRecord). Return `nil` to omit the id.

Column options:
- `attribute` (Symbol) - used for label generation and sort links
- `label` (String, optional) - custom header text; defaults to humanised attribute
- `primary` (Boolean, optional) - renders as `<th scope="row">`; defaults to first column
- `sortable` (Boolean, optional) - show sort link when `query:` is provided; defaults to true
- `render` (Proc, required) - receives (record), returns cell content

### `l_ui_format_datetime(value)`

Formats a date/time value as `"%-d %b %Y, %H:%M"` (e.g. "15 Apr 2026, 10:30"). Returns `nil` for `nil` input. Useful inside `render:` procs for date columns.

```erb
<%= l_ui_table(@users,
  columns: [
    { attribute: :name, primary: true, render: ->(r) { link_to r.name, user_path(r) } },
    { attribute: :email, render: ->(r) { r.email } },
    { attribute: :created_at, label: "Joined", render: ->(r) { l_ui_format_datetime(r.created_at) } },
  ],
  actions: ->(r) { link_to "Edit", edit_user_path(r), class: "l-ui-button l-ui-button--outline l-ui-button--small" },
  caption: "Users",
  query: @q,
  turbo_frame: "users") %>
```

## Form

```ruby
l_ui_form(record, fields:, url:, method: nil, submit: nil, multipart: nil)
```

- `record` (ActiveRecord) - the model instance
- `fields` (Array<Hash>) - field definitions (see below)
- `url` (String) - form action URL
- `method` (Symbol, optional) - HTTP method override
- `submit` (String, optional) - submit button text; defaults to "Create" for new records and "Save" for persisted records
- `multipart` (Boolean, optional) - override multipart encoding. Defaults to auto-detection: `true` when any field is `:file`, otherwise `false`. Pass `true`/`false` to force.

If you need control beyond these options, override the partial in your host app by creating `app/views/layered/ui/managed_resource/_form.html.erb` (Rails view lookup prefers the host's copy), or write the form directly with `form_with` and reuse `layered_ui/shared/form_errors`, `layered_ui/shared/label`, and `layered_ui/shared/field_error`.

Renders a complete form with all fields, error summary, and submit button via the `layered/ui/managed_resource/form` partial.

Field options:
- `attribute` (Symbol) - model attribute
- `as` (Symbol, optional) - field type; auto-detected from column type. Supported: `:string`, `:text`, `:email`, `:password`, `:number`, `:tel`, `:url`, `:search`, `:date`, `:datetime`, `:time`, `:month`, `:week`, `:color`, `:range`, `:file`, `:select`, `:checkbox`, `:hidden`. Forms automatically become `multipart` when any field is `:file`.
- `label` (String, optional) - custom label text; defaults to humanised attribute
- `required` (Boolean, optional) - marks field as required; default false
- `hint` (String, optional) - help text below the field
- `collection` (Array, optional) - required for `:select` type; e.g. `[['Label', value], ...]`
- `include_blank` (Boolean or String, optional) - for `:select` fields; defaults to `true`. Pass a string to use as the blank option's label, or `false` to omit it. Suppressed when `prompt:` is set
- `prompt` (String, optional) - for `:select` fields; prompt text shown as the first option, only selectable when no value is set
- `placeholder` (String, optional) - input placeholder text

```erb
<%= l_ui_form(@post,
  fields: [
    { attribute: :title, required: true },
    { attribute: :body, as: :text },
    { attribute: :category, as: :select, collection: Category.pluck(:name, :id) },
    { attribute: :published, as: :checkbox },
  ],
  url: posts_path) %>
```

### Form utility helpers

```ruby
l_ui_normalise_field(record, config)  # Normalise a raw field config into canonical form
l_ui_field_error_id(record, attribute)  # Error element ID for aria-describedby
l_ui_field_hint_id(record, attribute)   # Hint element ID for aria-describedby
```

## Modal

```ruby
l_ui_modal(title:, id: nil, heading_level: :h3, container: {}, &block)
```

- `title` (String) - heading shown in the modal header and used for `aria-labelledby`
- `id` (String, optional) - DOM id for the `<dialog>`; defaults to an auto-generated id
- `heading_level` (Symbol, optional) - heading tag for the title (e.g. `:h2`, `:h3`). Defaults to `:h3`
- `container` (Hash, optional) - extra HTML attributes for the wrapping `<div>` (e.g. `class:`)
- `&block` - the block's content is the modal body; call `m.trigger(**options, &block)` inside it to render a colocated trigger button

```erb
<%= l_ui_modal(title: "Socials") do |m| %>
  <% m.trigger(class: "l-ui-button l-ui-button--outline") do %>
    Open socials
  <% end %>
  <p>Body content.</p>
<% end %>
```

Renders the trigger `<button>` (if `m.trigger` is called), the `<dialog class="l-ui-modal">` with a header (title + close button), and wires the `l-ui--modal` Stimulus controller, including backdrop-click close.

If the trigger contains only an icon (no visible text), pass `aria-label:` to `m.trigger` so the button has an accessible name.

`m.trigger` renders a colocated trigger button. To open the same modal from elsewhere on the page (or to have multiple triggers), give the modal a known `id:` and add `data-l-ui-modal-open="<that id>"` to any button:

```erb
<%= l_ui_modal(title: "Confirm", id: "confirm-modal") do |m| %>
  <% m.trigger(class: "l-ui-button") do %>Open<% end %>
  <p>Body content.</p>
<% end %>

<button type="button" data-l-ui-modal-open="confirm-modal">Open from elsewhere</button>
```

The button does not need to be inside the helper's wrapper, and no `data-controller` or `data-action` is required - the `l-ui--modal` controller listens at the document level for clicks on `[data-l-ui-modal-open]` matching its dialog id.

Calling `dialog.showModal()` directly is not supported - it bypasses the `l-ui--modal` controller and skips scroll lock, focus restoration, open-count tracking, and the screen-reader announcement.

## Header

```ruby
l_ui_theme_toggle      # Renders the dark/light theme toggle button
l_ui_authentication    # Renders Devise login/register buttons (no-op when signed in or when Devise routes are absent)
l_ui_navigation_toggle # Renders the hamburger that toggles the sidebar (only when navigation items exist or a user is signed in)
```

Use these when overriding the header actions group with `:l_ui_header_actions` to compose your own bar from the default building blocks. The header also exposes `:l_ui_header_actions_start` and `:l_ui_header_actions_end` yields to prepend or append items without replacing the defaults, and `:l_ui_header_links` for inline links beside the logo.

```erb
<% content_for :l_ui_header_actions do %>
  <%= link_to "Docs", docs_path, class: "l-ui-button l-ui-button--ghost l-ui-button--small" %>
  <%= l_ui_theme_toggle %>
  <%= l_ui_authentication %>
  <%= l_ui_navigation_toggle %>
<% end %>
```

## Authentication

```ruby
l_ui_user_signed_in?   # Returns true if current user is present
l_ui_current_user      # Returns the current user object
l_ui_devise_installed? # Returns true if Devise is loaded
```

Configure the current user method:

```ruby
# config/initializers/layered_ui.rb
Layered::Ui.current_user_method = :current_member
```

## Shared partials

### Form errors summary

```erb
<%= render "layered_ui/shared/form_errors", item: @user %>
```

### Individual field error

```erb
<%= render "layered_ui/shared/field_error", object: @user, field: :email %>
```

### Form label

```erb
<%= render "layered_ui/shared/label", form: f, field: :email, name: "Email", required: true %>
```

### Search field (inside `l_ui_search_form` block)

```erb
<%= render "layered_ui/shared/search_field", form: f, field: :name_cont,
    label: "Name", placeholder: "Enter name" %>
```

### Search select (inside `l_ui_search_form` block)

```erb
<%= render "layered_ui/shared/search_select", form: f, field: :status_eq,
    label: "Status", options: ["Active", "Inactive"], include_blank: "Any" %>
```
