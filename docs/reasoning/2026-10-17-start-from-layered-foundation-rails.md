---
title: Start from layered-foundation-rails
date: 2026-10-17
paths:
  - Gemfile
  - config/
  - app/views/layouts/
  - .kamal/
  - Dockerfile
request: https://github.com/layered-ai-public/layered-foundation-rails
---

## Change

Started the app from the layered-foundation-rails template: Rails 8.1 on SQLite, with
Solid Queue, Solid Cache and Solid Cable, Hotwire through importmap, Tailwind, the
layered-ui-rails layout and components, and Kamal for deploys.

## Why

These are the Rails 8 defaults, chosen so a new app runs on one server with nothing
else alongside it: the database, jobs, cache and websockets all live in SQLite on a
single volume. layered-ui-rails gives every page an accessible (WCAG 2.2 AA) layout and
theming from the first commit, so features start from shared components rather than
one-off markup.

## Ruled out

- **PostgreSQL and Redis** - the usual pairing, but two more services to run, back up
  and pay for before the app needs them.
- **A JavaScript bundler and npm** - importmap and Hotwire cover server-rendered pages
  without a build step to maintain.
- **A managed platform (Heroku, Render)** - simpler on day one, but Kamal deploys to
  infrastructure the app's owner controls, with secrets kept in their own accounts.

## Trade-offs

SQLite allows one writer at a time and lives on one server's disk, so the app scales up
rather than out, and backups mean copying that volume. Jobs, cache and websockets share
the same database as the app.

## Revisit if

The app needs more than one web server, sustained write load contends on SQLite, or a
feature needs a client-side build (a large React surface, for example).

## Outcome

The template's test suite and CI pass.
