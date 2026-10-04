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

An accessible Rails 8.1 starter template. Clone it, and your next app begins with a solid, good-looking, WCAG 2.2 AA foundation instead of a blank slate.

Out of the box you get:

- **[layered-ui-rails](https://layered-ui-rails.layered.ai/)** - a layout, navigation, and component library tuned for accessibility.
- **Tailwind CSS** - wired up and ready to extend.
- **WCAG 2.2 AA** UI - accessible defaults baked into the layout and components.
- **Kamal deployment** - a guided skill that takes you from a bare server to HTTPS in production.
- **Agent setup skills** - the rename, Devise, and git-reset tasks below are driven by an `AGENTS.md` that lets your AI coding agent set the app up for you.

Optional, layered-ui-compatible companions you can add when you need them:

- **[layered-assistant-rails](https://github.com/layered-ai-public/layered-assistant-rails)** - drop-in AI chat assistant UI.
- **[layered-resource-rails](https://github.com/layered-ai-public/layered-resource-rails)** - scaffold accessible CRUD resources that match the layered-ui look and feel.

## Getting started

**Quick start via Rails template** - for a minimal new app with layered-ui-rails wired up:

```bash
rails new myapp --css tailwind \
  -m https://raw.githubusercontent.com/layered-ai-public/layered-foundation-rails/main/template.rb
```

This generates a fresh Rails 8.1 app, installs `layered-ui-rails`, swaps in the layered-ui layout, and adds a Hello World pages controller.

**Clone the foundation repo** - for the full starter, including the deployment and setup skills:

```bash
git clone https://github.com/layered-ai-public/layered-foundation-rails.git myapp
cd myapp
bin/rails layered:foundation:setup            # or just ask your AI coding agent to get started
```

The `setup` task renames the app from `LayeredFoundationRails` to your chosen name across the codebase, replaces `README.md` and `AGENTS.md` with fresh scaffolds, generates `config/credentials.yml.enc` and `config/master.key` if the app has no credentials yet (an existing `config/credentials.yml.enc` is kept - if its `config/master.key` is missing, the task tells you where to get it), and removes the licensing and template files you no longer need. The repo ships an `AGENTS.md`, so opening the project in any AI coding agent and asking it to get started will run this for you - just give it a name.

**Or set up from GitHub** - if you created your repo from this one on GitHub, you can run setup there without cloning: go to Actions → Set up app → Run workflow and enter the CamelCase name. `.github/workflows/setup.yml` runs the setup task on a `layered-setup` branch and opens a pull request with the result. If that branch is already there from a failed run, it's replaced; if it has an open PR, the workflow stops and names the PR. Before you run it:

- Turn on "Allow GitHub Actions to create and approve pull requests" under Settings → Actions → General, or the PR step will fail.
- If the repo has no `config/credentials.yml.enc`, the workflow won't commit the one it generates, because its `config/master.key` would be lost with the runner. After merging, run `EDITOR=true bin/rails credentials:edit` locally, commit `config/credentials.yml.enc`, and keep `config/master.key` safe.
- PRs opened by the workflow's `GITHUB_TOKEN` don't trigger CI. Close and reopen the PR to run it. (Layered avoids this by unticking the `open_pull_request` input, which pushes the branch without opening a PR, and opening the PR itself with its GitHub App token.)

Once setup has run, the workflow just fails with an explanation. You can delete it.

### Adding authentication (optional)

A separate task adds [Devise](https://github.com/heartcombo/devise) and wires it into the layered-ui layout - styled sign-in and registration views, header login/register buttons, and sidebar user info, with no extra configuration:

```bash
bin/rails layered:foundation:install_devise
```

It adds the gem, runs the Devise install and model generators, migrates, and can optionally require sign-in app-wide. The model name defaults to `User`.

### Adding an AI assistant (optional)

[layered-assistant-rails](https://github.com/layered-ai-public/layered-assistant-rails) adds a drop-in AI assistant side-panel that matches the layered-ui layout. The gem is pre-listed (commented out) in the `Gemfile` - enable it, then install its version-matched agent skill:

```bash
# 1. Uncomment the layered-assistant-rails line in the Gemfile, then:
bundle install

# 2. Install the skill so it stays in sync with the gem:
bin/rails generate layered:assistant:install_agent_skill
```

The skill walks your AI coding agent through mounting and embedding the assistant panel. Don't hand-roll the wiring - the installed skill is matched to the gem version.

### Adding CRUD resources (optional)

[layered-resource-rails](https://github.com/layered-ai-public/layered-resource-rails) gives you convention-over-config CRUD - accessible index/show/form views with search, sort, and pagination that match the layered-ui look and feel. It's also pre-listed (commented out) in the `Gemfile`:

```bash
# 1. Uncomment the layered-resource-rails line in the Gemfile, then:
bundle install

# 2. Install the skill so it stays in sync with the gem:
bin/rails generate layered:resource:install_agent_skill
```

Then ask your AI coding agent to build a resource - it'll follow the skill to generate the resource class, routes, and CRUD actions rather than guessing the API.

### Resetting git history (optional)

The starter's git history isn't yours, so a separate task wipes it for a clean slate - it removes `.git` and can re-initialise a fresh repo with an initial commit:

```bash
bin/rails layered:foundation:reset_git
```

> Each task runs interactively by default. Open the project in your AI coding agent to have it run them for you, or see `AGENTS.md` for the non-interactive invocations.

## Deploying with Kamal

This repo ships a [`kamal-deploy`](.claude/skills/kamal-deploy/SKILL.md) agent skill that wires `config/deploy.yml` and `.kamal/secrets` to a standard single-server target. It assumes:

- **One Ubuntu/Debian server** at a single public IP - no load balancer, no separate job host.
- **Root SSH** by default (works on most stock Ubuntu/Debian cloud images). Switch `ssh.user:` in `config/deploy.yml` if your image disables root login.
- **SQLite** on a persistent named Docker volume - survives redeploys, no separate DB service.
- **Let's Encrypt SSL** terminated by `kamal-proxy` on the same box; requires DNS for the domain to point at the server.
- **Local registry** (`localhost:5555`) tunnelled over SSH - no Docker Hub / GHCR account required.
- **ENV-driven target** so the committed config is reusable across environments:

  ```bash
  export KAMAL_DEPLOY_IP=127.0.0.1
  export KAMAL_DEPLOY_DOMAIN=app.example.com
  export KAMAL_SSH_KEY=~/.ssh/your_server_key

  bin/kamal setup        # first time only
  bin/kamal deploy
  ```

### Deploying from GitHub Actions

`.github/workflows/deploy.yml` runs `bin/kamal setup` on demand (Actions → Deploy with Kamal → Run workflow). `setup` installs Docker on a fresh server and is safe to rerun. Before the first run, add these under Settings → Secrets and variables → Actions:

| Name | Kind | Value |
| --- | --- | --- |
| `SSH_PRIVATE_KEY` | Secret | Private key that can SSH into the server as `ssh.user` |
| `RAILS_MASTER_KEY` | Secret | Contents of your `config/master.key` |
| `KAMAL_DEPLOY_IP` | Variable | The server's public IP |
| `KAMAL_DEPLOY_DOMAIN` | Variable | The domain pointed at that IP |

The workflow checks all four are set before it deploys. Its optional `destination` input is passed to Kamal as `-d`.

See the skill for the full first-time recipe (server bootstrap, database initialisation, optional hardening) and the "when to outgrow this setup" notes.

## Contributing

This project is still in its early days. We welcome issues, feedback, and ideas - they genuinely help shape the direction of the project. That said, we're holding off on accepting pull requests for now to stay focused on getting the foundations right. Thank you for your patience and interest. See [CLA.md](CLA.md) for the full policy.

## License

Released under the [Apache 2.0 License](LICENSE).

Copyright 2026 LAYERED AI LIMITED (UK company number: 17056830). See [NOTICE](NOTICE) for attribution details.

## Trademarks

The source code is fully open, but the layered.ai name, logo, and brand assets are trademarks of LAYERED AI LIMITED. The Apache 2.0 license does not grant rights to use the layered.ai branding. Forks and redistributions must use a distinct name. See [TRADEMARK.md](TRADEMARK.md) for the full policy.
