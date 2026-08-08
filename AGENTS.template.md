# AGENTS.md

Guide for AI coding agents (and humans) working in this repository. Keep it concise
and high-signal - it's read on every task.

## Rules of engagement (read first)

- **Never add colours, palettes, or design-token changes without asking.** This
  includes ad-hoc Tailwind colour utilities (`bg-blue-500`, `text-*`, `border-*`). The
  default neutral scheme that ships with layered-ui stays untouched unless the user has
  explicitly asked for branding. See [Styling rules](#styling-rules).
- **Enabling an optional layered gem? Install its skill and read it before writing any
  code against it.** The skill won't appear in your skill list until you generate it -
  so you won't be reminded it exists. See [Bundled agent skills](#bundled-agent-skills---use-them).
- **Don't add new gems without discussion and confirmation.**

## Project overview

TODO: one paragraph on what this app does and who it's for.

## First-time setup

Install dependencies before doing anything else - a fresh clone won't boot until the
gem bundle is in place:

```bash
bundle install      # install gems (run this first on a fresh checkout)
bin/setup           # prepares the app: deps, db, and friends
bin/dev             # start the dev server (Procfile.dev: Rails + Tailwind watch)
```

Run the test suite and linters before committing:

```bash
bin/rails test
bin/rubocop -a
```

## The stack

This app is built on the Rails 8.1 using the layered-foundation-rails template (https://github.com/layered-ai-public/layered-foundation-rails). Key gems:

- **rails ~> 8.1**, **propshaft**, **sqlite3**, **puma**, **solid_queue / solid_cache / solid_cable**
- **importmap-rails**, **turbo-rails**, **stimulus-rails** - Hotwire, no bundler/npm
- **tailwindcss-rails ~> 4** - utility CSS, compiled via `bin/dev`
- **layered-ui-rails** - WCAG 2.2 AA layout, components, helpers, theming (always present)
- **layered-resource-rails** - convention-over-config CRUD (search/sort/pagination) *(enable in Gemfile if needed)*
- **layered-assistant-rails** - AI assistant side-panel *(enable in Gemfile if needed)*
- **kamal** - single-server Docker deploy

## Optional: authentication with Devise

layered-ui-rails auto-detects Devise: styled auth views, header login/register buttons,
and sidebar user info light up with no extra configuration. If the user wants
authentication and `lib/tasks/layered/foundation/install_devise.rake` still exists,
run the bundled task rather than installing Devise by hand:

```bash
NON_INTERACTIVE=1 bin/rails "layered:foundation:install_devise[User]"
```

The model name defaults to `User`; a non-`User` name also configures
`Layered::Ui.current_user_method` to match. `NON_INTERACTIVE` auto-confirms every
prompt (including app-wide `authenticate_user!`); run it interactively to answer
prompt-by-prompt. The task removes itself on success - if it's gone, Devise is
already installed or was set up manually.

### The security options

The task offers two security options, both recommended and both auto-accepted under
`NON_INTERACTIVE`. Whether this app took them is visible in
`config/initializers/devise.rb` and the model.

**The security baseline** - written as config rather than left as advice, so it holds
whether or not anyone reads this file:

- **12-character minimum password.**
- **Lockout after 10 failed attempts**, auto-unlocking after an hour (`:lockable`).
- **30-minute idle session timeout** (`:timeoutable`).
- **Paranoid mode** - auth responses don't reveal whether an account exists.

Declining leaves Devise's own defaults: a 6-character minimum and no lockout.

**Breached-password checking** (`devise-pwned_password`) - rejects passwords that
appear in known breaches. This is what makes the length minimum mean something; on its
own, 12 characters still accepts `aaaaaaaaaaaa`. It queries the Have I Been Pwned API,
so sign-up and password changes make an outbound HTTPS call.

**Do not weaken whatever this app chose unless the user explicitly asks.** If a
requirement genuinely conflicts, say so and let them decide rather than quietly
relaxing it.

## Testing

The default test runner is Rails' built-in Minitest (`bin/rails test`). Lean on it
instead of booting a web server to click around - starting `bin/dev` to eyeball that a
route works is slow and proves less than a focused test.

- **Reach for integration tests to prove endpoints are wired up.** A short
  `ActionDispatch::IntegrationTest` that hits a path and asserts the response
  (`get manage_posts_path; assert_response :success`) is the fastest way to confirm
  routing, the controller, the layout, and auth all line up. This is usually all you
  need to verify a feature is connected - no browser required.
- **Test what *this app* adds, not the framework.** Rails 8's Minitest defaults are
  scoped to the code the host app wires up and any custom logic it introduces. Cover
  your own routes, controller actions, scopes (e.g. a `manage`-scoped query on `Post`),
  validations, and business rules.
- **Don't test the Rails framework or the layered gems' internals.** Rails itself and
  the layered-* engines have their own test suites - re-testing that `belongs_to`
  works, that layered-ui renders a component, or that layered-resource paginates is
  wasted effort. Assert on the behaviour your app is responsible for, and trust the
  gems for theirs.

## Layout conventions

The body class (set via the `l_ui_add_body_class` helper) decides how a page reads:

- **Landing / marketing** - `l-ui-body--header-contained` for a centred, contained
  header, and wrap content in `l-ui-page__contained` for a max-width body. This is
  what `app/views/layouts/application.html.erb` ships with.
- **App / back-office** - full-width header (the engine default, so just omit
  `--header-contained`) plus `l-ui-body--always-show-navigation` to pin the sidebar
  open on desktop.

**Set these defaults structurally, with a layout per section - don't rely on each page
remembering to call `l_ui_add_body_class`.** Every controller inherits
`layouts/application`, so a page that forgets to override inherits the *landing*
defaults - which is why app/admin sections so often end up with a contained header and
a hidden sidebar. Keep `application` as the landing default, and give each app-style
section its own layout that sets the defaults once:

```erb
<%# app/views/layouts/manage.html.erb %>
<% l_ui_add_body_class "l-ui-body--always-show-navigation" %>

<% content_for :l_ui_navigation_items do %>
  <%= l_ui_navigation_item "Dashboard", manage_root_path, icon: "home" %>
<% end %>

<%= render template: "layouts/layered_ui/application" %>
```

```ruby
# app/controllers/manage/base_controller.rb
class Manage::BaseController < ApplicationController
  layout "manage"
  before_action :authenticate_user!
end
```

Now every controller under that base inherits the right header/sidebar automatically -
nothing to forget per page, and an individual page can still add its own
`l_ui_add_body_class` when a design calls for it.

The real gate on a privileged section is `authenticate_user!` on the base controller,
not the URL. A less guessable namespace than `/admin` is a mild nicety on top of that,
not a substitute for it - so name the section for what it is and lean on the auth.

## Page titles and descriptions

**Every page needs a descriptive `<title>` - this is WCAG 2.4.2 (Page Titled), not
optional.** The layered-ui layout renders `<title>` from `@page_title` and
`<meta name="description">` from `@page_description`, but only when they're set. To
guarantee no page ever ships title-less, `ApplicationController` sets a default
`@page_title` (the application name) in a `before_action`.

- **Override `@page_title` per action** with something specific and unique to the page
  (e.g. `@page_title = "Edit post"`), so titles distinguish pages for screen-reader and
  tabbed-browsing users. Set it in the controller action, not the view.
- **Set `@page_description`** on public/landing pages for the `<meta name="description">`
  tag. It's good practice (and helps SEO) but isn't required on every page.
- Set both *before* the view renders - assign them in the controller action (or a
  `before_action`), since the layout reads them at render time. A new section's base
  controller is a good place to set a section-wide default title.

## Bundled agent skills - use them

Project-local Claude Code skills live under `.claude/skills/`. They encode the
conventions of the underlying gems, so **prefer invoking the relevant skill over
guessing at APIs or hand-rolling equivalents.** New views and CRUD features should
start by consulting the skill.

The layered gems each own their skill and ship a generator that installs the version
matching the installed gem - so the skill never drifts from the code. Present by
default:

- **layered-ui-rails** - installed from the gem (matches the installed version); building views with the layout, components, helpers, and Stimulus controllers.
- **kamal-deploy** - maintained in this repo; first-time deploy, changing the deploy target, debugging `kamal deploy`.

The resource and assistant gems are optional (enable them in the `Gemfile` if needed).
**When you enable one, follow these steps in order - do not skip ahead to writing
code:**

1. Add the gem to the `Gemfile` and run `bundle install`.
2. Install its skill from the gem so the two stay in sync:

   ```bash
   # layered-resource-rails - resource classes, layered_resources routes, CRUD
   bin/rails generate layered:resource:install_agent_skill

   # layered-assistant-rails - mounting and embedding the AI assistant panel
   bin/rails generate layered:assistant:install_agent_skill
   ```

3. Invoke the newly installed skill and follow it. **Do not hand-roll resource classes,
   routes, CRUD actions, or assistant wiring from memory** - the skill is version-matched
   to the installed gem, and guessing the API is exactly how these features go wrong. The
   skill won't show up in your skill list until step 2 runs, so it's on you to install it
   before you start.

Re-run a generator after upgrading its gem to refresh the skill.

**Check for an existing helper before rolling your own.** layered-ui-rails ships a
full set of view helpers (`l_ui_*` prefix - see the skill's `references/HELPERS.md`)
and CSS classes (`l-ui-*` prefix, BEM - see `references/CSS.md`). Reach for those
first; only build something custom when nothing fits.

## Styling rules

Accessibility is not optional here. Branding is the user's call - ask, don't impose.

- **Never introduce colours or a scheme unprompted.** If the user hasn't said how they
  want the app to look, leave the default neutral layered-ui tokens exactly as they are.
  This applies to *any* colour decision, not just a formal palette - reaching for an
  ad-hoc Tailwind colour utility (`bg-blue-500`, `text-emerald-600`) on a badge, button,
  or alert is imposing a scheme just as much as overriding a token, and it breaks the
  theme toggle and contrast guarantees besides. If you think the design needs colour,
  ask first; use the existing `l-ui-*` semantic classes where one fits. When the user
  *does* want branding, you can offer to derive a scheme from an image or reference URLs
  they like - and once it's agreed, the **layered-ui-rails skill** covers how to apply
  colours, logos, and icons; consult it rather than hand-rolling overrides.
- **Don't overload the layered-ui overrides.** Override the design tokens for
  brand-level decisions, but keep project-specific styling in
  separate, app-owned CSS files rather than piling it into the token override block.
  Those files still follow the rules below - `l-ui-*` first, OKLCH tokens, strict BEM -
  unless the user explicitly overrides them.
- **WCAG 2.2 AA** is the baseline. Preserve semantic HTML, focus states, labels, and
  contrast. layered-ui components are already compliant - don't undo that.
- **Theming** - light/dark is driven by the layered-ui `l-ui--theme` toggle and CSS
  custom properties. Don't hardcode colors; theme through the tokens.
- **Colors use OKLCH.** Override design tokens as CSS custom properties *after* the
  layered-ui import. OKLCH gives perceptually-uniform mixing and predictable contrast.
  Use a converter like https://oklch.com/ to translate from hex/rgb.

  ```css
  :root      { --accent: oklch(0.58 0.19 255); --accent-foreground: oklch(1 0 0); }
  .l-ui--theme[data-theme="dark"] { --accent: oklch(0.72 0.14 255); }
  ```

- **CSS layering**, in order:

  1. **Prefer existing `l-ui-*` classes first** - buttons, cards, forms, alerts,
     navigation, panels, typography patterns, and the like are already provided.
  2. **Use Tailwind in views for non-semantic layout only.**
     - Good: `flex`, `grid`, `gap-4`, `items-center`, `mt-6`, `sm:grid-cols-2`.
     - Avoid: `bg-*`, `text-*`, `border-*`, `shadow-*`, `font-*` - anything that
       affects brand, theme, or design language.
  3. **Put shared UI rules in CSS files.** If something is repeated or becomes a
     component, create a **strict BEM** class (`block__element--modifier`) in CSS and
     theme it through the OKLCH custom-property tokens - don't scatter the same
     utility soup across multiple templates. Factor it into a partial / view component.
     **Compose these classes from Tailwind with `@apply` rather than hand-rolling raw
     CSS** - reach for the utilities you'd otherwise put in the template (layout,
     spacing, sizing) and only drop to plain declarations for the themed tokens that
     `@apply` can't express:

     ```css
     .card__header {
       @apply flex items-center gap-3 px-4 py-3;
       background: var(--surface);
       color: var(--foreground);
     }
     ```

     **Name new classes to mirror layered-ui-rails conventions** where a comparable
     pattern exists: follow its BEM structure (e.g. `card__header--active` rather than
     an ad-hoc `myCardHead`), so custom components read as a natural extension of the
     design system. App-defined classes don't need a prefix - that keeps them clearly
     distinct from the engine's `l-ui-*` namespace.
  4. **Never bypass the tokens for themed decisions.** Colours, surfaces, borders,
     focus states, and typography tone come from the design system's tokens, not from
     Tailwind colour/state utilities.

## Suggested sections to fill in

- **Architecture** - where domain logic lives, naming/file-layout conventions, testing style.
- **Domain glossary** - product-specific terms an agent wouldn't infer from the code.
- **Do / don't** - guardrails (e.g. "run `bin/rubocop -a` before committing").
- **External systems** - issue trackers, dashboards, runbooks, docs outside this repo.
