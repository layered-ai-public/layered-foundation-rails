# layered-foundation-rails

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![CI](https://github.com/layered-ai-public/layered-foundation-rails/actions/workflows/ci.yml/badge.svg)](https://github.com/layered-ai-public/layered-foundation-rails/actions/workflows/ci.yml)
[![WCAG 2.2 AA](https://img.shields.io/badge/WCAG_2.2-AA-green)](https://www.w3.org/WAI/WCAG22/quickref/)
[![Website](https://img.shields.io/badge/Website-layered.ai-purple)](https://www.layered.ai/)
[![GitHub](https://img.shields.io/badge/GitHub-layered--ui--rails-black)](https://github.com/layered-ai-public/layered-foundation-rails)
[![Discord](https://img.shields.io/badge/Discord-join-5865F2)](https://discord.gg/aCGqz9Bx)
[![YouTube](https://img.shields.io/badge/YouTube-subscribe-FF0000)](https://www.youtube.com/@UseLayeredAi)
[![X](https://img.shields.io/badge/X-follow-000000)](https://x.com/UseLayeredAi)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-follow-0A66C2)](https://www.linkedin.com/company/uselayeredai/)

A pre-configured Rails 8.1 starter built around [layered-ui-rails](https://layered-ui-rails.layered.ai/). Clone it, and your next Rails app starts with a solid, good-looking, accessible foundation.

## To get started, choose one of the following methods

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

The setup task rewrites the module/class name, the `snake_case` gem-style name, and the `dashed-name` across the codebase, replaces `README.md` and `AGENTS.md` with fresh scaffolds, removes the licensing/template files no longer needed (including the setup task itself), and optionally removes the `.git` directory so you can start fresh with `git init`.

## Contributing

This project is still in its early days. We welcome issues, feedback, and ideas - they genuinely help shape the direction of the project. That said, we're holding off on accepting pull requests for now to stay focused on getting the foundations right. Thank you for your patience and interest. See [CLA.md](CLA.md) for the full policy.

## License

Released under the [Apache 2.0 License](LICENSE).

Copyright 2026 LAYERED AI LIMITED (UK company number: 17056830). See [NOTICE](NOTICE) for attribution details.

## Trademarks

The source code is fully open, but the layered.ai name, logo, and brand assets are trademarks of LAYERED AI LIMITED. The Apache 2.0 license does not grant rights to use the layered.ai branding. Forks and redistributions must use a distinct name. See [TRADEMARK.md](TRADEMARK.md) for the full policy.
