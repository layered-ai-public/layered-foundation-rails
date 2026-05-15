---
name: kamal-deploy
description: Configures and deploys this Rails 8 app to a single-server production target with Kamal — SQLite on a persistent volume, Let's Encrypt SSL via kamal-proxy, and ENV-driven server/domain/SSH-key so the same config works for multiple environments. Use when wiring up first-time Kamal deployment, changing the deploy target, debugging `kamal deploy`, or adjusting secrets/proxy/registry config.
metadata:
  author: layered.ai
  version: "1.0"
---

# kamal-deploy

Rails 8 ships with Kamal preconfigured (`config/deploy.yml`, `.kamal/secrets`, `bin/kamal`, `Dockerfile`). This skill adapts the generated config for the standard layered.ai deploy shape:

- **One web server** at a single IP (no load balancer, no `job:` host).
- **SQLite** on a named Docker volume so the DB survives redeploys.
- **Let's Encrypt SSL** terminated by `kamal-proxy` on the same box.
- **ENV-driven** target (`KAMAL_DEPLOY_IP`, `KAMAL_DEPLOY_DOMAIN`, `KAMAL_SSH_KEY`) so the committed config is reusable across staging/prod.
- **Local registry** (`localhost:5555`) — Kamal tunnels the push over SSH, so no Docker Hub account is required for a single-server deploy. Switch to a hosted registry only when you outgrow one server.

The Rails getting-started guide (<https://guides.rubyonrails.org/getting_started.html#deploying-to-production>) covers the conceptual flow; this skill is the concrete recipe for *this* repo.

## Prerequisites

Before deploying, confirm:

1. **Docker is running locally** — Kamal builds the image on your workstation.
2. **The server is reachable** — `ssh -i $KAMAL_SSH_KEY ubuntu@$KAMAL_DEPLOY_IP` succeeds. Root SSH is typically disabled on Ubuntu cloud images, which is why we deploy as `ubuntu`.
3. **DNS points the domain at the server** — `dig +short $KAMAL_DEPLOY_DOMAIN` returns `$KAMAL_DEPLOY_IP`. Let's Encrypt issuance fails otherwise.
4. **`config/master.key` exists** — `.kamal/secrets` reads it for `RAILS_MASTER_KEY`. If missing, generate credentials with `bin/rails credentials:edit` before deploying.

## Configure `config/deploy.yml`

Edit the generated `config/deploy.yml` so the server, proxy host, and SSH key come from ENV. Leave the service/image name as `layered_foundation_rails` (or whatever `bin/rails layered:foundation:setup` rewrote it to).

Key changes from the Rails default:

```yaml
servers:
  web:
    - <%= ENV.fetch("KAMAL_DEPLOY_IP") %>

proxy:
  ssl: true
  host: <%= ENV.fetch("KAMAL_DEPLOY_DOMAIN") %>
  app_port: 3000

ssh:
  user: ubuntu
  keys:
    - <%= ENV["KAMAL_SSH_KEY"] || "~/.ssh/id_rsa" %>
```

Notes:

- Use `ENV.fetch` (not `ENV[]`) for IP and domain so a missing value fails loudly instead of deploying nowhere.
- `ssh.user: ubuntu` — we deploy as the default non-root user on Ubuntu cloud images. Root SSH is typically disabled on hardened images and would fail. The user must be in the `docker` group before `kamal setup` runs (see "Server bootstrap" below).
- `proxy.ssl: true` enables Let's Encrypt. Rails 8's generated `config/environments/production.rb` already sets `config.assume_ssl` and `config.force_ssl` — leave them on.
- Keep the default `volumes:` entry (`<service>_storage:/rails/storage`); it's where SQLite and Active Storage files live.
- Keep `registry.server: localhost:5555` for the single-server setup.
- Keep `builder.arch: amd64` unless deploying to ARM.

## Configure `.kamal/secrets`

The generated `.kamal/secrets` already contains `RAILS_MASTER_KEY=$(cat config/master.key)` — that's all that's needed for env-only secrets. If `config/master.key` is gitignored (it should be), every developer who deploys needs their own copy. The deploy ENV vars (`KAMAL_DEPLOY_IP`, etc.) are *not* secrets in the Kamal sense — they're build-time inputs read by the ERB in `deploy.yml`, so they don't belong in `.kamal/secrets`.

## Server bootstrap (before `kamal setup`)

`kamal setup` installs Docker via `get.docker.com` and creates the `kamal` network — but it does **not** patch the OS, install missing utilities, or grant the SSH user Docker access. On a fresh Ubuntu box, do this once as `ubuntu` over SSH before running `kamal setup`:

```bash
ssh -i $KAMAL_SSH_KEY ubuntu@$KAMAL_DEPLOY_IP bash <<'EOF'
set -e
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
sudo apt install -y docker.io curl
sudo usermod -aG docker ubuntu
EOF
```

Then **close and re-open the SSH session** (or run the next step in a new shell) so the new group membership takes effect — otherwise `kamal setup` will hit "permission denied" talking to the Docker socket.

Optional hardening worth doing on a server that faces the public internet:

- `sudo ufw allow 22,80,443/tcp && sudo ufw enable` — only kamal-proxy + SSH need to be reachable.
- `sudo apt install -y unattended-upgrades fail2ban` — automatic security patches and brute-force protection.
- Disable password SSH in `/etc/ssh/sshd_config` (`PasswordAuthentication no`) once key-based auth is verified working.

## Deploy

Set the three ENV vars and run `kamal deploy`. First deploy also needs `kamal setup` to install Docker and kamal-proxy on the server:

```bash
export KAMAL_DEPLOY_IP=178.128.44.128
export KAMAL_DEPLOY_DOMAIN=app.example.com
export KAMAL_SSH_KEY=~/.ssh/your_server_key

# First time only: bootstraps Docker + kamal-proxy on the server, then deploys.
bin/kamal setup

# Subsequent deploys:
bin/kamal deploy
```

For repeated use, put the exports in a `.env.deploy` (gitignored) and `source` it before deploying — keeps the IP/domain out of shell history.

### Database initialisation

You don't need to run `db:setup` manually. The Rails 8 `bin/docker-entrypoint` runs `bin/rails db:prepare` before booting the server, which on a fresh SQLite volume creates the DB, loads `schema.rb`, and runs `db:seeds`. On subsequent deploys it migrates any pending changes.

If you ever need to force a reset (destructive — wipes the SQLite file in the volume):

```bash
bin/kamal app exec "bin/rails db:reset DISABLE_DATABASE_ENVIRONMENT_CHECK=1"
```

## Common operations

The repo's `deploy.yml` defines these aliases:

```bash
bin/kamal console   # bin/rails console on the running container
bin/kamal shell     # bash on the running container
bin/kamal logs      # tail Rails logs
bin/kamal dbc       # bin/rails dbconsole
```

Other useful commands:

- `bin/kamal app exec "bin/rails db:migrate"` — run migrations out-of-band (the default release process runs them on deploy).
- `bin/kamal proxy logs` — kamal-proxy / Let's Encrypt issuance logs. Check here when SSL is stuck.
- `bin/kamal redeploy` — rebuild and push without bumping the version tag.
- `bin/kamal rollback <version>` — flip back to a prior image.

## Troubleshooting

- **`KAMAL_DEPLOY_IP` unset** — `ENV.fetch` raises before Kamal opens an SSH connection. Re-`source` your env file.
- **Let's Encrypt fails with "no A record"** — DNS hasn't propagated, or the domain points elsewhere. Verify with `dig +short`.
- **`Error response from daemon: ... localhost:5555`** — the local registry tunnel didn't come up. Two likely causes: (a) the SSH key can't auth — test with `ssh -i $KAMAL_SSH_KEY ubuntu@$KAMAL_DEPLOY_IP`; (b) the `ubuntu` user isn't yet in the `docker` group, or the membership hasn't taken effect — re-run the server bootstrap and start a fresh SSH session before retrying.
- **SQLite data vanished after a deploy** — the named volume in `volumes:` was renamed. Volume names are derived from the `service:` value; renaming the service orphans the old volume. `docker volume ls` on the server shows what's there.
- **Asset 404s right after deploy** — `asset_path: /rails/public/assets` (already in the generated config) handles the cross-version bridge; don't remove it.

## When to outgrow this setup

This recipe is deliberately single-box. Move off it when any of these become true:

- **You need a second web server** — drop `proxy.ssl: true` (terminate SSL at a load balancer instead) and switch the registry to a hosted one (Docker Hub, GHCR, registry.digitalocean.com).
- **SQLite write contention shows up** — add a `db` accessory (Postgres/MySQL) and set `DB_HOST` in `env.clear`.
- **Background jobs need their own box** — uncomment the `job:` server block and unset `SOLID_QUEUE_IN_PUMA`.
