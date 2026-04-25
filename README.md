# layered-foundation-rails

A pre-configured Rails 8.1 starter built around [layered-ui-rails](https://layered-ui-rails.layered.ai/). Clone it, and your next Rails app starts with a solid, good-looking, accessible foundation instead of a blank slate.

---

## Two Ways to Use This

**1. Quick start via Rails template** — for a minimal new app with layered-ui-rails wired up:

```bash
rails new myapp --css tailwind \
  -m https://raw.githubusercontent.com/layered-ai/layered-foundation-rails/main/template.rb
```

This generates a fresh Rails 8.1 app, installs `layered-ui-rails`, runs its install generator, swaps in the layered-ui layout, and adds a Hello World pages controller. Nothing else.

**2. Clone the foundation repo** — for a richer starter with the full Solid suite, CI workflows, Kamal config, and (over time) batteries like Devise, Pundit, SAML, and an admin layout:

```bash
git clone https://github.com/layered-ai/layered-foundation-rails.git myapp
cd myapp
bin/rails app:setup      # Interactive — prompts for the new CamelCase name
```

The setup task rewrites the module/class name, the `snake_case` gem-style name, and the `dashed-name` across the codebase, replaces `README.md` and `AGENTS.md` with fresh scaffolds, removes the licensing/template files no longer needed (`LICENSE`, `NOTICE`, `TRADEMARK.md`, `CLA.md`, `template.rb`, the setup task itself), and optionally removes the `.git` directory so you can start fresh with `git init`.

## License

Released under the [Apache 2.0 License](LICENSE).

Copyright 2026 LAYERED AI LIMITED (UK company number: 17056830). See [NOTICE](NOTICE) for attribution details.

## Trademarks

The source code is fully open, but the layered.ai name, logo, and brand assets are trademarks of LAYERED AI LIMITED. The Apache 2.0 license does not grant rights to use the layered.ai branding. Forks and redistributions must use a distinct name. See [TRADEMARK.md](TRADEMARK.md) for the full policy.

## Contributing

- [CLA.md](CLA.md) - contributor license agreement

This project is still in its early days. We welcome issues, feedback, and ideas - they genuinely help shape the direction of the project. That said, we're holding off on accepting pull requests until after the 1.0 release so we can stay focused on getting the core foundations right. Once we're there, we'd love to open things up to broader contributions. Thanks for your patience and interest!
