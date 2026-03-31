# layered-foundation-rails

A pre-configured Rails 8.1 starter built around [layered-ui-rails](https://layered-ui-rails.layered.ai/) — an open-source design system that ships accessible, well-designed UI components (header, sidebar, panels, modals, tabs, and more) with WCAG 2.2 AA compliance and a perfect Lighthouse score out of the box. Clone it, and your next Rails app starts with a solid, good-looking foundation instead of a blank slate.

**Stack:** Rails 8.1 · Ruby 4.0.2 · layered-ui-rails · Tailwind CSS 4.4 · Hotwire · Solid Suite · Kamal

---

## Getting Started

```bash
bin/setup     # Install dependencies, prepare the database, and start the dev server
```

Or step by step:

```bash
bundle install
bin/rails db:prepare
bin/dev       # Starts Rails + Tailwind CSS watcher via Foreman on port 3000
```

Modify pages#index to change the "Hello World" page.

---

## Development

```bash
bin/dev                # Start the development server (port 3000)
bin/rails console      # Rails console
bin/rails db:prepare   # Create and migrate the database
```

---

## Testing

```bash
bin/rails test           # Run all tests
bin/rails test:system    # Run system tests (Capybara + Selenium)
bin/ci                   # Full CI suite: lint, security scans, and tests
```

---

## Code Quality

```bash
bin/rubocop        # Lint Ruby (Omakase style)
bin/brakeman       # Rails security scan
bin/bundler-audit  # Check gems for known vulnerabilities
```

---

## Architecture

| Concern | Choice |
|---|---|
| Database | SQLite3 (all environments) |
| Background jobs | Solid Queue |
| Caching | Solid Cache |
| WebSockets | Solid Cable |
| Asset pipeline | Propshaft |
| JavaScript | Import maps (no bundler) |
| CSS | Tailwind CSS 4.4 |
| UI / Layout | [Layered UI Rails](https://github.com/layered-ui/layered-ui-rails) |
| Deployment | Kamal (Docker) |

No Redis required — Solid Queue, Cache, and Cable are all backed by SQLite.

Production uses separate SQLite database files for the primary DB, cache, queue, and cable, persisted via a Docker volume at `/rails/storage`.

---

## Deployment

Deployment uses [Kamal](https://kamal-deploy.org). Configure `config/deploy.yml` for your environment, then:

```bash
bin/kamal deploy      # Deploy to production
bin/kamal console     # Rails console on the remote server
bin/kamal logs        # Tail production logs
bin/kamal shell       # Bash shell on the remote server
bin/kamal dbc         # Database console on the remote server
```

**Required environment variable:**

| Variable | Description |
|---|---|
| `RAILS_MASTER_KEY` | Decrypts Rails credentials in production |

## License

Released under the [Apache 2.0 License](LICENSE).

Copyright 2026 LAYERED AI LIMITED (UK company number: 17056830). See [NOTICE](NOTICE) for attribution details.

## Trademarks

The source code is fully open, but the layered.ai name, logo, and brand assets are trademarks of LAYERED AI LIMITED. The Apache 2.0 license does not grant rights to use the layered.ai branding. Forks and redistributions must use a distinct name. See [TRADEMARK.md](TRADEMARK.md) for the full policy.

## Contributing

- [CLA.md](CLA.md) - contributor license agreement

This project is still in its early days. We welcome issues, feedback, and ideas - they genuinely help shape the direction of the project. That said, we're holding off on accepting pull requests until after the 1.0 release so we can stay focused on getting the core foundations right. Once we're there, we'd love to open things up to broader contributions. Thanks for your patience and interest!
