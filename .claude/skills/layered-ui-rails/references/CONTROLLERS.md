# Stimulus controllers

All controllers use the `l-ui--` namespace and are auto-registered via importmap. No manual registration is needed in the host app.

## Theme (`l-ui--theme`)

Toggles dark/light mode with localStorage persistence and system preference detection.

**Targets:** `button`
**Actions:** `toggle`
**Storage key:** `theme` (stores `"dark"` or `"light"`)

The layout already wires this up. To add your own toggle button:

```html
<button data-controller="l-ui--theme"
        data-action="click->l-ui--theme#toggle"
        data-l-ui--theme-target="button"
        aria-pressed="false">
  Toggle theme
</button>
```

## Navigation (`l-ui--navigation`)

Responsive sidebar navigation with backdrop overlay on mobile.

**Targets:** `navigation`, `backdrop`, `toggleButton`, `openIcon`, `closeIcon`
**Actions:** `toggle`, `close`
**Keyboard:** Escape to close
**Behaviour:** Locks body scroll while the mobile overlay is open

The layout wires this up automatically. Navigation items are populated via `content_for :l_ui_navigation_items`.

## Modal (`l-ui--modal`)

Native `<dialog>` wrapper with focus trap, scroll lock, and focus restoration.

**Targets:** `dialog`
**Actions:** `open`, `close`, `closeOnBackdrop`

```html
<div data-controller="l-ui--modal">
  <button data-action="click->l-ui--modal#open" class="l-ui-button">
    Open modal
  </button>
  <dialog data-l-ui--modal-target="dialog" class="l-ui-modal">
    <div class="l-ui-modal__header">
      <h2>Title</h2>
      <button data-action="click->l-ui--modal#close" class="l-ui-button--icon">
        Close
      </button>
    </div>
    <div class="l-ui-modal__body">
      Content here.
    </div>
  </dialog>
</div>
```

Features:
- Focus moves to first focusable element on open
- Focus returns to trigger element on close
- Body scroll is locked while open
- Supports nested modals

## Tabs (`l-ui--tabs`)

Accessible tabbed interface with keyboard navigation.

**Targets:** `tab`, `panel`
**Actions:** `select`, `keydown`
**Keyboard:** Arrow Left/Right, Home, End

```html
<div data-controller="l-ui--tabs">
  <div role="tablist" class="l-ui-tabs__list">
    <button role="tab" data-l-ui--tabs-target="tab"
            data-action="click->l-ui--tabs#select keydown->l-ui--tabs#keydown"
            class="l-ui-tabs__tab l-ui-tabs__tab--active"
            aria-selected="true" tabindex="0">
      Tab 1
    </button>
    <button role="tab" data-l-ui--tabs-target="tab"
            data-action="click->l-ui--tabs#select keydown->l-ui--tabs#keydown"
            class="l-ui-tabs__tab"
            aria-selected="false" tabindex="-1">
      Tab 2
    </button>
  </div>
  <div role="tabpanel" data-l-ui--tabs-target="panel">
    Content 1
  </div>
  <div role="tabpanel" data-l-ui--tabs-target="panel" hidden>
    Content 2
  </div>
</div>
```

## Panel (`l-ui--panel`)

Resizable side panel. Full-width overlay on mobile, docked sidebar on desktop.

**Targets:** `container`, `hideButton`, `actionButton`
**Actions:** `toggle`
**Keyboard:** Cmd/Ctrl+I to toggle
**Storage key:** `panelOpen` (stores `"true"` or `"false"`)

The layout wires this up automatically. Panel content is populated via `content_for :l_ui_panel_heading` and `content_for :l_ui_panel_body`.

## Panel button (`l-ui--panel-button`)

Draggable floating action button that toggles the panel.

**Actions:** `queueToggle`, `cycleCorner`, `startDrag`, `drag`, `stopDrag`
**Keyboard:** Cmd/Ctrl+Alt+1/2/3/4 to move to corners
**Storage key:** `panelButtonPosition` (JSON with `{edge, top}`)

Features:
- Drag with mouse or touch
- Auto-snaps to nearest screen edge
- Double-click cycles through four corners
- 5px drag threshold prevents accidental clicks

## Panel resize (`l-ui--panel-resize`)

Drag handle for resizing the panel width on desktop.

**Targets:** `container`, `handle`
**Actions:** `startResize`, `resize`, `stopResize`, `handleKeydown`, `resetWidth`
**Keyboard:** Arrow Left/Right (10px), Shift+Arrow (50px), Home/End
**Storage key:** `panelWidth` (pixel value)

- Min width: 240px
- Default width: 480px
- Double-click handle to reset to default

## Search form (`l-ui--search-form`)

Manages multi-scope search forms with parameter preservation and Turbo frame support.

**Values:** `scope` (String, default `"q"`)
**Actions:** `preserve`, `clear`, `rewriteLink`

```html
<form data-controller="l-ui--search-form"
      data-l-ui--search-form-scope-value="q"
      data-action="submit->l-ui--search-form#preserve"
      data-turbo-frame="results">
  <!-- search fields -->
  <button type="button" data-action="click->l-ui--search-form#clear">
    Clear
  </button>
</form>
```

When multiple search forms exist on one page (each with a different `scope` value), submitting one form automatically preserves the other forms' query parameters. The `page` param and any scoped page param matching the scope (e.g. `users_page` for scope `users_q`) are reset on submit so pagination returns to page 1.

**`rewriteLink`** - merges current URL params into a clicked link's href. Useful for pagination links inside Turbo Frames where the server-rendered href may be missing params from other scopes. Attach to a parent element (e.g. the Turbo Frame):

```html
&lt;%= turbo_frame_tag "users_collection", data: { turbo_action: "advance",
      controller: "l-ui--search-form", l_ui__search_form_scope_value: "users_q",
      action: "click->l-ui--search-form#rewriteLink" } do %&gt;
  &lt;%= l_ui_search_form(@users_q, url: users_path, fields: [:name, :email],
                       clear: true, turbo_frame: "users_collection") %&gt;
  &lt;%= l_ui_table(@users, ..., query: @users_q, turbo_frame: "users_collection") %&gt;
  &lt;%= l_ui_pagy(@users_pagy) %&gt;
&lt;% end %&gt;
```
