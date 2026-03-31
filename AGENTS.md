# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/dev          # Start development server (Rails + Tailwind CSS watcher via Foreman)
bin/setup        # Install dependencies, prepare DB, optionally start dev server
bin/ci           # Run full CI suite locally (lint, security scans, tests)

bin/rails test                        # Run all tests
bin/rails test test/path/to/file.rb   # Run a single test file
bin/rails test:system                 # Run system tests (Capybara + Selenium)

bin/rubocop      # Lint Ruby code (Omakase style)
bin/brakeman     # Rails security scanner
bin/bundler-audit # Check gems for known vulnerabilities
```

## Architecture

This is a **Rails 8.1 foundation/starter** app — intentionally minimal, meant to be built upon.

**Key stack choices:**
- **Solid suite** (Solid Cache, Solid Queue, Solid Cable) — all background jobs, caching, and WebSockets use SQLite-backed Solid gems; no Redis required
- **Hotwire** (Turbo + Stimulus) — UI interactivity; no SPA framework
- **Import maps** — JavaScript module loading; no bundler (webpack/esbuild)
- **Propshaft** — asset pipeline
- **Layered UI Rails** (`layered-ui-rails ~> 0.2.0`) — design system gem; the application layout delegates to its template (`app/views/layouts/application.html.erb`)
- **Tailwind CSS 4.4** — styles live in `app/assets/tailwind/`; Tailwind runs as a separate process in `bin/dev`
- **Kamal** — Docker-based deployment (`config/deploy.yml`, `Dockerfile`)

**Database:** SQLite3 for all environments. Production uses separate database files for cache, queue, and cable (configured in `config/database.yml`).

**Current app state:** Only a `PagesController#index` root route exists. No domain models or migrations have been added yet.

**CI pipelines** (`.github/workflows/`): scan_ruby (Brakeman + bundler-audit), scan_js (importmap audit), lint (RuboCop), test, system-test — all run on Ruby 4.0.2/Ubuntu.
