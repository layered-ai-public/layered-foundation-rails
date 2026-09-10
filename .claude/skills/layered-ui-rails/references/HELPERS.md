# View helpers

All helpers are prefixed `l_ui_` and are available in all views automatically.

## Body modifiers

```ruby
l_ui_add_body_class(*modifiers)
```

Registers one or more body modifier classes (see the [body modifiers](CSS.md) list). Call it from any template or layout **above** the engine layout render; calls accumulate, so a shared layout and an individual page can each contribute without clobbering one another. Pass full class names:

```erb
<% l_ui_add_body_class "l-ui-body--always-show-navigation" %>
<% l_ui_add_body_class "l-ui-body--glass-header", "l-ui-body--flush-top" %>
<% l_ui_add_body_class "l-ui-body--hide-header" if minimal_chrome? %>
```

The resulting classes are deduplicated and space-joined, so repeated modifiers are harmless.

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
           actions_label: "Actions", floating_actions: false,
           query: nil, url: nil, turbo_frame: nil, row_id: nil)
```

- `records` (ActiveRecord::Relation or Array) - the collection to render
- `columns` (Array<Hash>) - column definitions (see below)
- `caption` (String, optional) - visually hidden table caption for accessibility
- `actions` (Proc, optional) - receives (record), returns action cell content
- `actions_label` (String) - header text for the actions column, default "Actions"
- `floating_actions` (Boolean) - pin the actions column to the right-hand edge of the scroll container while the table scrolls horizontally (adds `l-ui-table--floating-actions`), default false
- `query` (Ransack::Search, optional) - enables sortable column headers
- `url` (String, optional) - sort link URL (passed to `l_ui_sort_link`)
- `turbo_frame` (String, optional) - turbo frame target for sort links
- `row_id` (Proc, optional) - receives (record), returns the `<tr>` id. Defaults to `dom_id(record)` for records that respond to `to_key` (ActiveRecord). Return `nil` to omit the id.

The rendered table is wrapped in an `l-ui-scroll-hint` element wired to the `l-ui--scroll-hint` controller, which fades the clipped edge when the table overflows horizontally.

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
- `as` (Symbol, optional) - field type; auto-detected from column type. Supported: `:string`, `:text`, `:email`, `:password`, `:number`, `:tel`, `:url`, `:search`, `:date`, `:datetime`, `:time`, `:month`, `:week`, `:color`, `:range`, `:file`, `:select`, `:combobox`, `:checkbox`, `:hidden`. Forms automatically become `multipart` when any field is `:file`.
- `label` (String, optional) - custom label text; defaults to humanised attribute
- `required` (Boolean, optional) - marks field as required; default false
- `hint` (String, optional) - help text below the field
- `collection` (Array, optional) - required for `:select`; for `:combobox` either this or `url:` is required; e.g. `[['Label', value], ...]`
- `include_blank` (Boolean or String, optional) - for `:select` fields; defaults to `true`. Pass a string to use as the blank option's label, or `false` to omit it. Suppressed when `prompt:` is set
- `prompt` (String, optional) - for `:select` fields; prompt text shown as the first option, only selectable when no value is set
- `placeholder` (String, optional) - input placeholder text
- any other key passes through to the underlying field helper as an HTML attribute (`:combobox` excepted - see below)

A `:combobox` field renders its own label and hint, adds the field's error element to its `aria-describedby`, and defaults `selected:` to the record's current value. That, and its keyword-only signature, give three rules:

- It takes only `l_ui_combobox`'s own options - `url:`, `multiple:`, `create:`, `create_name:`, `reorder:`, `min_chars:`, `text:`, `selected:`, `disabled:`, `describedby:`, `container:`, `id:`. Every other key raises, `prompt:` and `include_blank:` included; extra HTML attributes go on `container:`.
- `multiple:` is inferred from the attribute rather than defaulting to `l_ui_combobox`'s `true`: an `_ids` attribute, an array column, or one already holding an array is multiple; anything else is single, so a scalar attribute posts a scalar rather than an array Active Record would cast to `nil`. Pass `multiple:` explicitly to override.
- Pass `selected: [[@post.user.name, @post.user_id]]` whenever the record's value might not be in the options - a `url:` collection never holds it, and nor does a scoped, paginated or filtered `collection:`. Without it, the field raises on an edit form.

```erb
<%= l_ui_form(@post,
  fields: [
    { attribute: :title, required: true },
    { attribute: :body, as: :text },
    { attribute: :category, as: :select, collection: Category.pluck(:name, :id) },
    { attribute: :published, as: :checkbox },
    { attribute: :tag_ids, as: :combobox, collection: Tag.pluck(:name, :id) },
    { attribute: :author_id, as: :combobox, url: options_users_path },
  ],
  url: posts_path) %>
```

### Form utility helpers

```ruby
l_ui_normalise_field(record, config)  # Normalise a raw field config into canonical form
l_ui_field_error_id(record, attribute)  # Error element ID for aria-describedby
l_ui_field_hint_id(record, attribute)   # Hint element ID for aria-describedby
l_ui_field_describedby(record, attribute, hint: false)  # Space-joined hint + error IDs for aria-describedby
l_ui_field_value(record, attribute)     # Record's current value; default :combobox selection
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

## Popover

```ruby
l_ui_popover(id: nil, placement: :bottom, align: :start, open: false, container: {}, &block)
```

- `id` (String, optional) - DOM id for the popover element; defaults to an auto-generated id
- `placement` (Symbol, optional) - `:top`, `:bottom` (default), `:left`, or `:right`. Flips automatically if it would overflow the viewport
- `align` (Symbol, optional) - `:start` (default) flushes the popover's leading edge with the trigger's; `:end` flushes its trailing edge instead. For example, `placement: :bottom, align: :end` hangs the popover down and to the left of a trigger at the right end of a row
- `open` (Boolean, optional) - when `true`, the popover opens as soon as its Stimulus controller connects, shown and positioned in the same task so it never paints unpositioned. Useful for re-opening a popover after a form submission re-renders the page (e.g. `open: params[:filtering].present?`). Defaults to `false`
- `container` (Hash, optional) - extra HTML attributes for the wrapping `<div>` (e.g. `class:`)
- `&block` - the block's content is the popover body; call `p.trigger(**options, &block)` inside it to render the trigger button

```erb
<%= l_ui_popover(placement: :bottom) do |p| %>
  <% p.trigger(class: "l-ui-button l-ui-button--outline") do %>
    Options
  <% end %>
  <p>Popover content.</p>
<% end %>
```

Renders the trigger `<button popovertarget="...">` and the `popover="auto"` element (`class="l-ui-popover"`), and wires the `l-ui--popover` Stimulus controller for placement. Showing, hiding, light-dismiss (outside click), and Escape-to-close are all handled natively by the browser via the `popover` attribute - no Stimulus action is needed to open or close it.

If the trigger contains only an icon (no visible text), pass `aria-label:` to `p.trigger` so the button has an accessible name.

For a list of actions (e.g. a "more" menu on a table row), wrap the items in a `<div class="l-ui-popover__menu">` and give each link/button `l-ui-popover__menu-item` (add `l-ui-popover__menu-item--danger` for destructive actions, and an `<hr class="l-ui-popover__menu-divider">` to separate groups of items):

```erb
<%= l_ui_table(@users, columns: [...],
    actions: ->(r) {
      l_ui_popover(align: :end) do |p|
        p.trigger(class: "l-ui-button l-ui-button--outline l-ui-button--icon l-ui-button--small", "aria-label" => "Actions for #{r.name}") do
          image_tag "layered_ui/icon_more.svg", alt: "", class: "l-ui-icon l-ui-icon--sm", aria: { hidden: true }
        end
        tag.div(class: "l-ui-popover__menu") do
          safe_join([
            link_to("Edit", edit_user_path(r), class: "l-ui-popover__menu-item"),
            tag.hr(class: "l-ui-popover__menu-divider"),
            button_to("Delete", user_path(r), method: :delete, class: "l-ui-popover__menu-item l-ui-popover__menu-item--danger")
          ])
        end
      end
    }) %>
```

## Tag

```ruby
l_ui_tag(rounded: false, container: {}, &block)
```

Renders an interactive tag (`class="l-ui-tag"`) - e.g. an email recipient or an active filter. Visually related to `l-ui-badge` but a distinct control: a badge is a static styled span, while a tag is a container whose segments (label, remove) are separately interactive.

- `rounded` (Boolean, optional) - pill shape (matching `l-ui-badge--rounded`); defaults to `false` for the subtle badge radius
- `container` (Hash, optional) - extra HTML attributes for the wrapping `<div>` (e.g. `class:`)
- `&block` - declare segments on the builder; they render in call order. Use `<%` (not `<%=`) - segment content is captured by the builder

Builder methods:

- `t.text(content = nil, **opts, &block)` - static label segment (`<span class="l-ui-tag__text">`)
- `t.button(**opts, &block)` - button segment (`<button class="l-ui-tag__button">`); opens the tag's popover when one is declared
- `t.link(url, **opts, &block)` - link segment, styled like a button segment
- `t.remove(url = nil, **opts, &block)` - trailing remove segment (`l-ui-tag__remove`): a link when `url` is given, otherwise a button. Renders a ✕ icon unless the block supplies custom content. Pass `aria: { label: ... }` so it has an accessible name
- `t.popover(id: nil, placement: :bottom, align: :start, open: false, &block)` - attaches a popover; the block is the popover body. Options match `l_ui_popover`

Text, button, and link segments wrap their content in `<span class="l-ui-tag__label">`, which truncates long labels with an ellipsis when the tag is squeezed (the tag itself never grows past its container).

```erb
<%= l_ui_tag do |t| %>
  <% t.button(aria: { label: "Edit status filter" }) do %>
    Status: Active
  <% end %>
  <% t.remove remove_filter_path, aria: { label: "Remove status filter" },
       data: { turbo_frame: "results" } %>
  <% t.popover do %>
    <p>Filter controls.</p>
  <% end %>
<% end %>
```

When a popover is declared, the tag container itself becomes the `l-ui--popover` controller root and placement target - the popover aligns with the whole tag rather than the label button inside it - and button segments are wired to open it via `popovertarget`. A tag without a popover renders no Stimulus wiring.

## Combobox

```ruby
l_ui_combobox(name, collection: nil, form: nil, selected: nil, multiple: true,
              create: false, create_name: nil, reorder: false, url: nil,
              min_chars: 0, text: {}, id: nil, label: nil, hint: nil, placeholder: nil,
              required: false, disabled: false, describedby: nil, container: {})
```

Renders a token select (`class="l-ui-combobox"`): a text input with type-ahead filtering whose selections become removable tags, in the style of an email recipient field. Built on the ARIA combobox pattern - no third-party select library.

- `name` (String or Symbol) - the parameter, e.g. `"post[tag_ids]"`. A Symbol is resolved against `form:`
- `collection` (Array) - `["Label", value]` pairs, `{ label:, value: }` hashes, or plain strings. Required unless `url:` is given
- `form` (FormBuilder, optional) - derives parameter names from the builder for Symbol names
- `selected` (Array or value, optional) - selected values, or `["Label", value]` pairs / `{ label:, value: }` hashes where the label is not in `collection` (the only form a remote selection can take). A value with no label renders as a created token (requires `create:`)
- `multiple` (Boolean, default `true`) - multi select; `false` drops the `[]` suffix, replaces the token on choice, and closes the list
- `create` (Boolean, default `false`) - allow values outside the collection; requires `create_name:`
- `create_name` (String or Symbol) - parameter created values post under, keeping record IDs and free text unambiguous server-side
- `reorder` (Boolean, default `false`) - move controls plus mouse dragging (each token gains a decorative grip handle advertising the drag); parameters post in the displayed order
- `url` (String, optional) - endpoint searched as the user types; options come from it rather than from `collection:`
- `min_chars` (Integer, default `0`) - characters needed before a remote search runs; `0` searches as soon as the field is focused
- `text` (Hash, optional) - wording for every string the control shows, merged over `Layered::Ui::ComboboxHelper::COMBOBOX_TEXT`: `empty:` ("No matches"), `create:` ("Add “%{term}”"), `min_chars:` ("Type %{count} characters to search."), `progress:` ("Showing %{shown} of %{count} matches."), `error:`, `more_error:`. Placeholders use Rails' `%{name}` syntax; `progress: nil` drops the progress line; an unknown key raises
- `describedby` (String, optional) - extra element ids appended to the input's `aria-describedby`, for text rendered outside the control (a validation message, say)
- `label`, `hint`, `placeholder`, `required`, `disabled`, `id`, `container` - as for a normal field

Also available as a field type in `l_ui_form`: `{ attribute: :tag_ids, as: :combobox, collection: ... }`.

```erb
<%= form_with model: @post do |f| %>
  <%= l_ui_combobox(:tag_ids, form: f,
        label: "Tags",
        collection: Tag.pluck(:name, :id),
        selected: @post.tag_ids,
        create: true,
        create_name: :new_tag_names) %>
<% end %>

<%# post[tag_ids][]       => ["", "7"]  %>
<%# post[new_tag_names][] => ["urgent"] %>
```

Each selection carries its own hidden input, so the control submits with an ordinary form post, and a blank value is always posted first - clearing every token submits an empty collection instead of omitting the parameter and leaving the association untouched. Selections are announced through a local `role="status"` region, and the keyboard help is bound to the input with `aria-describedby`. Reordering exposes move buttons as well as dragging, since WCAG 2.2 SC 2.5.7 requires a single-pointer alternative to a drag.

### Remote options

With `url:`, options are fetched from that endpoint as the user types (debounced, with overtaken responses discarded) instead of being rendered up front and filtered in the browser. Matches load a page at a time, the next page appended as the end of the list is reached - by scrolling to its foot or by pressing Down on its last option, so the keyboard is not capped at the first page. A presentational note under the options (`class="l-ui-combobox__notice"`) says how far into the matches the list has got, or that they could not be loaded; a request in flight shows a spinner instead (trailing the field while searching, beside the note while a page loads), after a short delay so a quick answer never flashes one. Remote selections must be passed as `["Label", value]` pairs, since the browser has no collection to look a label up in.

```ruby
Layered::Ui::ComboboxOptions   # Controller concern building the JSON the endpoint answers with

l_ui_combobox_options(scope, label:, value: :id, search: nil, predicate: :cont,
                      combinator: :or, term: nil, page: nil, limit: 20)
```

- `scope` (Relation or model class) - what the user is allowed to see; the endpoint stays an ordinary action in the host app, authorised as any index is
- `label` (Symbol or Proc) - attribute, or callable taking the record, used for the option's label
- `value` (Symbol or Proc, default `:id`) - attribute, or callable, used for the option's value
- `search` (Array, defaults to `label`) - attributes the term is matched against; required when `label:` is a callable, since a computed label gives the database nothing to search on. An attribute neither backend can search raises rather than quietly matching everything
- `predicate` (Symbol, default `:cont`) - Ransack predicate for the match; `:i_cont` ignores case. Without Ransack only `:cont` and `:i_cont` can be built, and any other raises rather than quietly matching on something else
- `combinator` (Symbol, default `:or`) - how the search attributes combine, `:or` or `:and`; honoured on both paths, and anything else raises
- `term`, `page` - default to `params[:term]` and `params[:page]`
- `limit` (Integer, default 20) - options per page

Ransack builds the predicate when it is available (so association attributes work) and Pagy takes the page; there is a plain `LIKE` plus `limit`/`offset` fallback, so neither gem is required. An unordered scope is ordered by the label so pages do not overlap.

```erb
<%= l_ui_combobox(:author_id, form: f, multiple: false,
      url: options_users_path, min_chars: 2,
      selected: [[@post.author.name, @post.author_id]]) %>
```

```ruby
class UsersController < ApplicationController
  include Layered::Ui::ComboboxOptions

  def options
    render json: l_ui_combobox_options(policy_scope(User), label: :name, search: [:name, :email])
  end
end

# GET /users/options?term=ali&page=1
# { "options": [{ "label": "Alice Johnson", "value": "2" }], "page": 1, "pages": 1, "count": 1 }
```

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
l_ui_user_signed_in?      # Returns true if current user is present
l_ui_current_user         # Returns the current user object
l_ui_devise_installed?    # Returns true if Devise is loaded
l_ui_settings_screen?     # Returns true on the Settings screen (Devise registrations#edit)
l_ui_new_registration_path # Devise registration path for the configured scope, or nil
l_ui_edit_registration_path # Devise account settings path for the configured scope, or nil
l_ui_new_session_path      # Devise sign-in path for the configured scope, or nil
l_ui_destroy_session_path  # Devise sign-out path for the configured scope, or nil
```

Configure the current user method, and the Devise scope used to build the login/register/settings/logout paths (`new_registration_path`, `edit_registration_path`, `new_session_path`, `destroy_session_path`):

```ruby
# config/initializers/layered_ui.rb
Layered::Ui.current_user_method = :current_member
Layered::Ui.devise_scope = :member
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
