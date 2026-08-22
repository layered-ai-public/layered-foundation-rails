---
name: kamal-deploy
description: Configures and deploys this Rails 8 app to a single-server production target with Kamal - SQLite on a persistent volume, Let's Encrypt SSL via kamal-proxy, and ENV-driven server/domain/SSH-key so the same config works for multiple environments. Use when wiring up first-time Kamal deployment, changing the deploy target, debugging `kamal deploy`, or adjusting secrets/proxy/registry config.
metadata:
  author: layered.ai
  version: "1.1"
---

# kamal-deploy

Rails 8 ships with Kamal preconfigured (`config/deploy.yml`, `.kamal/secrets`, `bin/kamal`, `Dockerfile`). This skill adapts the generated config for the standard layered.ai deploy shape:

- **One web server** at a single IP (no load balancer, no `job:` host).
- **SQLite** on a named Docker volume so the DB survives redeploys.
- **Let's Encrypt SSL** terminated by `kamal-proxy` on the same box.
- **ENV-driven** target (`KAMAL_DEPLOY_IP`, `KAMAL_DEPLOY_DOMAIN`, `KAMAL_SSH_KEY`) so the committed config is reusable across staging/prod.
- **Local registry** (`localhost:5555`) - Kamal tunnels the push over SSH, so no Docker Hub account is required for a single-server deploy. Switch to a hosted registry only when you outgrow one server.

The Rails getting-started guide (<https://guides.rubyonrails.org/getting_started.html#deploying-to-production>) covers the conceptual flow; this skill is the concrete recipe for *this* repo.

## Prerequisites

Before deploying, confirm:

1. **Docker is running locally** - Kamal builds the image on your workstation.
2. **The server is reachable** - `ssh -i $KAMAL_SSH_KEY root@$KAMAL_DEPLOY_IP` succeeds. If the image disables root SSH, switch the configured user (see "SSH user" below).
3. **DNS points the domain at the server** - `dig +short $KAMAL_DEPLOY_DOMAIN` returns `$KAMAL_DEPLOY_IP`. Let's Encrypt issuance fails otherwise.
4. **`config/master.key` exists** - `.kamal/secrets` reads it for `RAILS_MASTER_KEY`. If missing, generate credentials with `bin/rails credentials:edit` before deploying.

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
  user: root
  keys:
    - <%= ENV["KAMAL_SSH_KEY"] || "~/.ssh/id_rsa" %>
  keys_only: true
```

Notes:

- Use `ENV.fetch` (not `ENV[]`) for IP and domain so a missing value fails loudly instead of deploying nowhere.
- `ssh.user: root` is the default - works out of the box on most stock Ubuntu/Debian cloud images. See "SSH user" below if your image disables root SSH.
- `ssh.keys_only: true` forces Kamal to offer only the configured key. Without it, a workstation `ssh-agent` with several keys loaded can hit the server's `MaxAuthTries` and get disconnected before Kamal offers the right one - even though a direct `ssh -i <key>` works fine (that forces the key). Pure win when a single key is configured, which is the case here.
- `proxy.ssl: true` enables Let's Encrypt. Rails 8's generated `config/environments/production.rb` already sets `config.assume_ssl` and `config.force_ssl` - leave them on.
- Keep the default `volumes:` entry (`<service>_storage:/rails/storage`); it's where SQLite and Active Storage files live.
- Keep `registry.server: localhost:5555` for the single-server setup.
- Keep `builder.arch: amd64` unless deploying to ARM.

## Configure `.kamal/secrets`

The generated `.kamal/secrets` already contains `RAILS_MASTER_KEY=$(cat config/master.key)` - that's all that's needed for env-only secrets. If `config/master.key` is gitignored (it should be), every developer who deploys needs their own copy. The deploy ENV vars (`KAMAL_DEPLOY_IP`, etc.) are *not* secrets in the Kamal sense - they're build-time inputs read by the ERB in `deploy.yml`, so they don't belong in `.kamal/secrets`.

## External Postgres/RDS target (alternative to SQLite)

Use this instead of the SQLite defaults above when the app's database is a pre-provisioned Postgres instance (e.g. RDS) rather than a Kamal-managed volume. This is different from the `db:` accessory mentioned in "When to outgrow this setup" below - an accessory is a Postgres container Kamal itself manages, whereas here Postgres already exists outside Kamal's control and the app just needs to be pointed at it. Key this branch off which adapter `config/database.yml` already declares (`sqlite3` vs `postgresql`) rather than assuming.

### Dockerfile

Swap the SQLite runtime package for the Postgres client library, and add the Postgres dev headers to the build stage (the `pg` gem needs them to compile - the runtime image doesn't):

```dockerfile
# build stage
RUN apt-get install --no-install-recommends -y build-essential libpq-dev ...

# final/runtime stage
RUN apt-get install --no-install-recommends -y libpq5 postgresql-client ...
```

### `config/database.yml`

If the host app already ships a Postgres/PostGIS `database.yml` with a hardcoded production username/password (common when inheriting from a previously Capistrano-deployed sibling app), rewrite the `production:` block to read from ENV instead - this is what makes the ENV-driven, multi-target story below actually reach the database, not just the server/domain/SSH key:

```yaml
production:
  <<: *default
  database: <%= ENV.fetch("DATABASE_NAME") %>
  host: <%= ENV.fetch("DATABASE_HOST") %>
  username: <%= ENV.fetch("DATABASE_USERNAME") %>
  password: <%= ENV.fetch("DATABASE_PASSWORD") %>
```

### `config/deploy.yml` and `.kamal/secrets`

- Add `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_NAME` to `env.clear`.
- Add `DATABASE_PASSWORD` to `env.secret` (alongside any other app secrets, e.g. `DEVISE_SECRET_KEY` or third-party API keys), with a matching passthrough line in `.kamal/secrets`.
- The `volumes:` entry stops being "the database" and becomes Active Storage-only - SQLite is what needed the persistent volume; Postgres lives outside the container entirely.

### RDS prerequisites

- `bin/docker-entrypoint`'s `db:prepare` call tries to *create* the database if it's missing, and Solid Cache/Queue/Cable each expect a sibling database next to the primary. Either grant the DB user `CREATEDB`, or pre-create all four databases (primary plus cache/queue/cable) before the first deploy.
- The RDS security group must allow inbound connections from the app server, not just your workstation.
- If the primary database was restored from a dump (e.g. migrating off Capistrano), check it for pending migrations before the app goes live - a restored snapshot can be behind `db/schema.rb`.

## Server bootstrap (before `kamal setup`)

`kamal setup` installs Docker via `get.docker.com` and creates the `kamal` network - but it does **not** patch the OS or install other utilities. On a fresh box, do this once as root before running `kamal setup`:

```bash
ssh -i $KAMAL_SSH_KEY root@$KAMAL_DEPLOY_IP bash <<'EOF'
set -e
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y
apt install -y docker.io curl
EOF
```

Optional hardening worth doing on a server that faces the public internet:

- `ufw allow 22,80,443/tcp && ufw enable` - only kamal-proxy + SSH need to be reachable.
- `apt install -y unattended-upgrades fail2ban` - automatic security patches and brute-force protection.
- Disable password SSH in `/etc/ssh/sshd_config` (`PasswordAuthentication no`) once key-based auth is verified working.

### SSH user

The skill (and `config/deploy.yml`) assumes root SSH is enabled - true for most stock DigitalOcean/Hetzner Ubuntu/Debian images. Stock **EC2** Ubuntu AMIs are the common exception: root login is disabled by default, so default to `ubuntu` (or `ec2-user` on Amazon Linux) there instead of treating it as a hardened-image edge case. If your image disables root login, instead:

1. Set `ssh.user:` in `config/deploy.yml` to the login user (e.g. `ubuntu`, `admin`, `ec2-user`).
2. Add that user to the `docker` group **before** running `kamal setup` - otherwise Kamal hits "permission denied" on the Docker socket. Run the bootstrap as that user with `sudo`, plus `sudo usermod -aG docker <user>`, then close and re-open the SSH session so group membership takes effect.

## Deploy

Set the three ENV vars and run `kamal deploy`. First deploy also needs `kamal setup` to install Docker and kamal-proxy on the server:

```bash
export KAMAL_DEPLOY_IP=127.0.0.1
export KAMAL_DEPLOY_DOMAIN=app.example.com
export KAMAL_SSH_KEY=~/.ssh/your_server_key

# First time only: bootstraps Docker + kamal-proxy on the server, then deploys.
bin/kamal setup

# Subsequent deploys:
bin/kamal deploy
```

For repeated use, put the exports in a `.env.deploy` (gitignored) and `source` it before deploying - keeps the IP/domain out of shell history.

### Multiple targets (staging/production/...)

For more than one deploy target, use one gitignored `.env.<target>` file per target (`.env.uat`, `.env.production`, ...), each defining that target's `KAMAL_DEPLOY_IP`/`_DOMAIN`/`_SSH_KEY` (plus `DATABASE_*` values if using the external Postgres/RDS branch above), with a committed `.env.<target>.example` template per target. Add `!/.env.*.example` to `.gitignore` alongside the existing `!/.env.example` so the templates stay tracked while the real files don't.

### Database initialisation

You don't need to run `db:setup` manually. The Rails 8 `bin/docker-entrypoint` runs `bin/rails db:prepare` before booting the server, which on a fresh SQLite volume creates the DB, loads `schema.rb`, and runs `db:seeds`. On subsequent deploys it migrates any pending changes.

If you ever need to force a reset (destructive - wipes the SQLite file in the volume):

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

- `bin/kamal app exec "bin/rails db:migrate"` - run migrations out-of-band (the default release process runs them on deploy).
- `bin/kamal proxy logs` - kamal-proxy / Let's Encrypt issuance logs. Check here when SSL is stuck.
- `bin/kamal redeploy` - rebuild and push without bumping the version tag.
- `bin/kamal rollback <version>` - flip back to a prior image.

## Troubleshooting

- **`KAMAL_DEPLOY_IP` unset** - `ENV.fetch` raises before Kamal opens an SSH connection. Re-`source` your env file.
- **Let's Encrypt fails with "no A record"** - DNS hasn't propagated, or the domain points elsewhere. Verify with `dig +short`.
- **`Error response from daemon: ... localhost:5555`** - the local registry tunnel didn't come up. Usually means the SSH key can't auth as the configured user; test with `ssh -i $KAMAL_SSH_KEY <ssh.user>@$KAMAL_DEPLOY_IP`. If you're using a non-root user, also confirm it's in the `docker` group (see "SSH user").
- **SQLite data vanished after a deploy** - the named volume in `volumes:` was renamed. Volume names are derived from the `service:` value; renaming the service orphans the old volume. `docker volume ls` on the server shows what's there.
- **Asset 404s right after deploy** - `asset_path: /rails/public/assets` (already in the generated config) handles the cross-version bridge; don't remove it.
- **`mkdir: .kamal/lock-<service>: File exists`** - a prior `kamal setup`/`deploy` was interrupted (Ctrl-C, timed-out approval, etc.) and left a stale lock on the server. Run `bin/kamal lock release` and retry.

## When to outgrow this setup

This recipe is deliberately single-box. Move off it when any of these become true:

- **You need a second web server** - drop `proxy.ssl: true` (terminate SSL at a load balancer instead) and switch the registry to a hosted one (Docker Hub, GHCR, registry.digitalocean.com).
- **SQLite write contention shows up** - add a `db` accessory (Postgres/MySQL) and set `DB_HOST` in `env.clear`, or point at an already-provisioned external instance per "External Postgres/RDS target" above.
- **Background jobs need their own box** - uncomment the `job:` server block and unset `SOLID_QUEUE_IN_PUMA`.
