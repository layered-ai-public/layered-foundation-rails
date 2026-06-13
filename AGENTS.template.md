# AGENTS.md

Guide for AI coding agents (and humans) working in this repository. Keep it concise
and high-signal - it's read on every task.

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

Don't add new gems without discussion and confirmation.

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

## Layout conventions

Default the body class via `content_for :l_ui_body_class` to match the page type:

- **Admin / back-office** - full-width header (the default) +
  `l-ui-body--always-show-navigation` to pin the sidebar open on desktop.
- **Landing / marketing** - `l-ui-body--header-contained` for the header, and wrap
  content in `l-ui-page__contained` for a max-width body.

These are sensible defaults, not rules - override when a design calls for it.

Mount admin behind an authenticated namespace (`authenticate_user!` on the base
controller). `/admin` works, but a less guessable namespace is advisable.

## Bundled agent skills - use them

Project-local Claude Code skills live under `.claude/skills/`. They encode the
conventions of the underlying gems, so **prefer invoking the relevant skill over
guessing at APIs or hand-rolling equivalents.** New views and CRUD features should
start by consulting the skill.

- **layered-ui-rails** - building views with the layout, components, helpers, and Stimulus controllers.
- **layered-resource-rails** - resource classes, mounting `layered_resources` routes, scaffolding CRUD.
- **layered-assistant-rails** - mounting and embedding the AI assistant panel.
- **kamal-deploy** - first-time deploy, changing the deploy target, debugging `kamal deploy`.

**Check for an existing helper before rolling your own.** layered-ui-rails ships a
full set of view helpers (`l_ui_*` prefix - see the skill's `references/HELPERS.md`)
and CSS classes (`l-ui-*` prefix, BEM - see `references/CSS.md`). Reach for those
first; only build something custom when nothing fits.

## Styling rules

Accessibility and the design system are not optional here.

- **Agree the colour scheme up front.** Before building anything visual, settle the
  palette - and the design tokens that support it - *with the user*. If they're not
  sure, ask them to share an image (a brand asset, a moodboard) or a few URLs of sites
  whose style they like, and derive the scheme from those. Pin down the accent,
  surfaces, and foregrounds early so views aren't restyled piecemeal later. If the user
  would rather not bother, the default neutral scheme that ships with layered-ui is a
  perfectly good choice - just leave the tokens as they are.
- **Don't overload the layered-ui overrides.** Override the design tokens for the
  brand-level decisions (the agreed scheme above), but keep project-specific styling in
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

- **CSS layering.** The rule in one line: *use `l-ui-*` classes wherever the design
  system has a pattern; use Tailwind utilities in views only for local layout,
  spacing, and responsive composition; never use Tailwind colour, typography, border,
  shadow, or state utilities for themed UI; for repeated or shared patterns, create a
  BEM-style component class in CSS and theme it with OKLCH tokens.* In order:

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
     focus states, typography tone, and interactive states come from the design
     system, not from Tailwind colour/state utilities - otherwise the theme toggle and
     WCAG contrast guarantees silently break.

  Note: Tailwind only compiles classes it sees in the host app's templates, so
  engine-provided patterns must use the copied `l-ui-*` classes, not raw utilities.

## Suggested sections to fill in

- **Architecture** - where domain logic lives, naming/file-layout conventions, testing style.
- **Domain glossary** - product-specific terms an agent wouldn't infer from the code.
- **Do / don't** - guardrails (e.g. "run `bin/rubocop -a` before committing").
- **External systems** - issue trackers, dashboards, runbooks, docs outside this repo.
