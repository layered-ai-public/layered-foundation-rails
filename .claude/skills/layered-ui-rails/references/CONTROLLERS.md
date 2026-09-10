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

## Navigation section (`l-ui--navigation-section`)

Collapsible navigation section with optional localStorage persistence. Wired up automatically by `l_ui_navigation_section` when `collapsible: true`.

**Targets:** `toggle`, `panel`
**Values:** `storageKey` (String, localStorage key), `forceOpen` (Boolean)
**Actions:** `toggle`
**Behaviour:** The server renders the section's default open/closed state (and forces it open when it contains the active item). On `connect`, if `forceOpen` is set the stored preference is ignored; otherwise the controller restores the user's stored preference. Clicking the toggle always works (so a force-opened section can still be collapsed) and writes the new state to localStorage.

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
      <button data-action="click->l-ui--modal#close" class="l-ui-button l-ui-button--icon">
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
<div class="l-ui-tabs" data-controller="l-ui--tabs">
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

## Popover (`l-ui--popover`)

Positions a native `popover`-attribute element relative to its trigger, with auto-flip near viewport edges. Showing, hiding, light-dismiss (outside click), and Escape-to-close are all handled by the browser via the `popover` attribute - this controller only handles placement.

**Targets:** `trigger`, `popover`
**Values:** `placement` (String, default `"bottom"`; one of `"top"`, `"bottom"`, `"left"`, `"right"`), `align` (String, default `"start"`; `"start"` or `"end"` - which edge of the popover flushes with the trigger on the cross axis), `open` (Boolean, default `false`; when true the popover opens as soon as the controller connects, shown and positioned in the same task so it never paints unpositioned - e.g. re-opening a filter popover after a form submission re-renders the page)

```html
<div data-controller="l-ui--popover">
  <button type="button" popovertarget="my-popover"
          data-l-ui--popover-target="trigger"
          class="l-ui-button l-ui-button--outline">
    Open popover
  </button>
  <div id="my-popover" popover="auto" class="l-ui-popover"
       data-l-ui--popover-target="popover">
    Content here.
  </div>
</div>
```

Features:
- Repositions on open, and while open on window resize/scroll
- Flips to the opposite side if the preferred placement would overflow the viewport
- `data-l-ui--popover-open-value="true"` opens the popover on connect without a flash of unpositioned content

## Combobox (`l-ui--combobox`)

Drives the token select rendered by `l_ui_combobox`: type-ahead filtering, selections held as tokens with their own hidden inputs, optional creation of values outside the collection, optional reordering, and optional remote options.

**Targets:** `control`, `tokens`, `token`, `input`, `listbox`, `option`, `empty`, `notice`, `noticeText`, `busy`, `moreSpinner`, `template`, `optionTemplate`, `status`
**Values:** `multiple` (Boolean, default `true`), `create` (Boolean, default `false`), `reorder` (Boolean, default `false`), `disabled` (Boolean, default `false`), `name` (String - parameter existing values post under), `createName` (String - parameter created values post under), `url` (String - endpoint searched as the user types; empty means filter in the browser), `minChars` (Number, default `0` - characters needed before a remote search runs), `text` (Object - the wording for the messages built here, from the helper's `text:` option; `%{name}` placeholders are substituted at use, and a key the caller emptied is left unsaid)
**Actions:** `focusInput`, `open`, `close`, `blur`, `scrolled`, `filter`, `keydown`, `selectOption`, `removeToken`, `moveTokenEarlier`, `moveTokenLater`, `dragstart`, `dragover`, `drop`, `dragend`

Features:
- Focus never leaves the input while the list is browsed; the highlight follows `aria-activedescendant`
- Down/Up/Home/End move the highlight, Enter chooses, Escape closes then clears, Backspace on the empty input removes the last token
- With nothing highlighted, Down enters the list at the first option and Up at the last, matching the ARIA combobox pattern; the highlight wraps at either end
- Choosing an already-selected option removes it again (multi select); single select replaces the token and closes
- In create mode, a term matching no option is offered as `Add "term"` and posts under `createName`
- Reorder mode disables the dead-end move control on the first and last token and moves focus so it is never lost; a disabled combobox is left alone, so its controls stay disabled
- Dragging is a pointer enhancement only, advertised by a decorative grip handle - the move buttons are the accessible path, as WCAG 2.2 SC 2.5.7 requires
- Selections, filter counts, and moves are announced through a local `role="status"` region
- With `url` set, each keystroke schedules a debounced fetch of `url?term=...`; the previous request is aborted and an overtaken response is dropped, so the list always answers what is currently typed. Leaving the field abandons a search in flight, so nothing spins beside a closed listbox and nothing is announced after focus has moved on. Responses replace the options wholesale, cloned from the `optionTemplate`, and the browser does no filtering of its own
- Further pages are appended as the end of a remote list is reached - within `LOAD_MORE_MARGIN` of its foot (the `scrolled` action, bound to the listbox), or on Down/End at the last option, so the keyboard is not capped at the first page. Down loads instead of wrapping while pages remain, and highlights the first newly loaded option; option ids run on across pages so `aria-activedescendant` can never point at a reused id
- The `notice` row carries only durable messages: how far into the matches the list has got, a failed request, and the character threshold. Each appended page is announced through the status region
- A request in flight shows a spinner rather than a message - `busy` (trailing the input) while searching, `moreSpinner` (in the notice row) while a page loads - after `SPINNER_DELAY`, so a fast response never flashes one. `aria-busy` goes on the listbox immediately, since it costs nothing and says the same thing to a screen reader

Use the `l_ui_combobox` helper (see HELPERS.md) rather than writing the markup by hand.

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

- Min width: 256px
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

## Scroll hint (`l-ui--scroll-hint`)

Fades the clipped edges of a horizontal scroller while more content is available in that direction, so it is obvious the region can be scrolled.

**Targets:** `scroller` (the scrollable element)
**Behaviour:** toggles `l-ui-scroll-hint--left`/`l-ui-scroll-hint--right` on the wrapper from the scroll position; updates on scroll and when the scroller or its content resizes. While the scroller overflows it is given `tabindex="0"` so keyboard users can scroll it (WCAG 2.1.1); the attribute is removed when it fits.

`l_ui_table` wires this up automatically. For hand-written tables (or any other horizontal scroller), wrap the scrolling element:

```html
<div class="l-ui-scroll-hint" data-controller="l-ui--scroll-hint">
  <div class="l-ui-table-container" data-l-ui--scroll-hint-target="scroller">
    <table class="l-ui-table">...</table>
  </div>
</div>
```
