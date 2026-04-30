# View helpers

All helpers are prefixed `l_ui_` and are available in all views automatically.

## Navigation

```ruby
l_ui_navigation_item(label, path, active: nil, &block)
```

- `label` (String) - link text
- `path` (String) - URL
- `active` (Boolean, optional) - force active state; defaults to `current_page?` check
- `&block` - optional nested navigation items

```erb
<% content_for :l_ui_navigation_items do %>
  <%= l_ui_navigation_item("Home", root_path) %>
  <%= l_ui_navigation_item("Products", products_path, active: true) do %>
    <%= l_ui_navigation_item("Electronics", electronics_path) %>
    <%= l_ui_navigation_item("Clothing", clothing_path) %>
  <% end %>
<% end %>
```

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
  <%= link_to "New user", new_user_path, class: "l-ui-button--primary" %>
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
  <%= f.submit "Search", class: "l-ui-button--primary" %>
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
           actions_label: "Actions", query: nil, url: nil, turbo_frame: nil)
```

- `records` (ActiveRecord::Relation or Array) - the collection to render
- `columns` (Array<Hash>) - column definitions (see below)
- `caption` (String, optional) - visually hidden table caption for accessibility
- `actions` (Proc, optional) - receives (record), returns action cell content
- `actions_label` (String) - header text for the actions column, default "Actions"
- `query` (Ransack::Search, optional) - enables sortable column headers
- `url` (String, optional) - sort link URL (passed to `l_ui_sort_link`)
- `turbo_frame` (String, optional) - turbo frame target for sort links

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
  actions: ->(r) { link_to "Edit", edit_user_path(r) },
  caption: "Users",
  query: @q,
  turbo_frame: "users") %>
```

## Form

```ruby
l_ui_form(record, fields:, url:, method: nil)
```

- `record` (ActiveRecord) - the model instance
- `fields` (Array<Hash>) - field definitions (see below)
- `url` (String) - form action URL
- `method` (Symbol, optional) - HTTP method override

Renders a complete form with all fields, error summary, and submit button via the `layered/ui/managed_resource/form` partial.

Field options:
- `attribute` (Symbol) - model attribute
- `as` (Symbol, optional) - field type; auto-detected from column type. Supported: `:string`, `:text`, `:email`, `:number`, `:date`, `:datetime`, `:select`, `:checkbox`, `:hidden`
- `label` (String, optional) - custom label text; defaults to humanised attribute
- `required` (Boolean, optional) - marks field as required; default false
- `hint` (String, optional) - help text below the field
- `collection` (Array, optional) - required for `:select` type; e.g. `[['Label', value], ...]`
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
