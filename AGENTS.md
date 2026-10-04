# AGENTS.md

Before doing anything else in this repo, the application needs to be renamed via the setup task. Handle this for the user using the steps below - don't start any other work until it's done.

## Preferred route: run it for them

1. Ask the user for the new CamelCase application name (e.g. `MyApp`). Validate it against `/\A[A-Z][A-Za-z0-9]*\z/` before proceeding.
2. Run the task non-interactively:

   ```bash
   NON_INTERACTIVE=1 bin/rails "layered:foundation:setup[MyApp]"
   ```

   `NON_INTERACTIVE` auto-confirms every prompt. Run interactively instead if the user wants to answer prompt-by-prompt - there is no per-prompt override.

## Fallback: have them run it interactively

If you can't or shouldn't run it on their behalf (e.g. they want to choose answers prompt-by-prompt, or you're in a read-only context), tell them to run:

```bash
bin/rails layered:foundation:setup
```

…and answer the prompts.

## Alternative: the GitHub Actions workflow

If the user would rather do it on GitHub (e.g. no local Ruby yet), `.github/workflows/setup.yml` runs the same task: Actions → Set up app → Run workflow, entering the CamelCase name. It runs the task on a `layered-setup` branch, pushes it, and opens a PR. If the branch already exists with an open PR, the workflow fails and names the PR. A branch without one is left over from a failed run, so the workflow replaces it. Points to pass on:

- The repo needs "Allow GitHub Actions to create and approve pull requests" enabled (Settings → Actions → General), or the PR step fails after pushing the branch.
- If the repo had no `config/credentials.yml.enc`, the workflow doesn't commit the one it generates, because its `config/master.key` can't leave the runner. After merging, they run `EDITOR=true bin/rails credentials:edit` locally and commit `config/credentials.yml.enc`.
- PRs opened by `GITHUB_TOKEN` don't trigger CI. Close and reopen the PR to run it. The `open_pull_request` input (default true) can be set to false to push the branch without opening a PR. Layered does this and opens the PR with its GitHub App token, so CI does run.
- After they merge, pull the branch locally and re-read `AGENTS.md`, just as after running the task yourself.

The setup task never edits `.github/workflows`, because `GITHUB_TOKEN` can't push changes there. Keep it that way when changing the task.

## What the task does

- Rewrites `LayeredFoundationRails`, `layered_foundation_rails`, and `layered-foundation-rails` to the new name across the codebase.
- Generates `config/credentials.yml.enc` and `config/master.key` (gitignored) if `config/credentials.yml.enc` is missing - production won't boot without a `secret_key_base`. The starter ships no credentials, so an existing file belongs to the app (Layered commits one when it creates an app) and is kept. If it exists but `config/master.key` doesn't, the task says so: get the key (for apps created in Layered, it's on the app's GitHub integration page) and save it as `config/master.key`.
- Drops starter-only files (`LICENSE`, `NOTICE`, `TRADEMARK.md`, `CLA.md`, `template.rb`, and the setup task itself).
- Replaces `README.md` and this `AGENTS.md` file with fresh scaffolds for the user (and their agents) to build on.

**After the task finishes, re-read `AGENTS.md`.** The setup task replaces this very file, so the instructions loaded into your context at the start of the session are now stale. Before doing any further work, use your file-reading tool to read the new `AGENTS.md` in full - it carries the real working rules for this app (styling, layout, bundled skills) that this starter version doesn't.

## Installing Devise (optional, separate task)

layered-ui-rails auto-detects Devise and provides styled auth views, header login/register buttons, and sidebar user info with no extra configuration. A separate task adds the gem, runs the `devise:install` and model generators, migrates, and optionally requires sign-in app-wide. Only offer it if the user wants authentication, and run it after the rename:

```bash
NON_INTERACTIVE=1 bin/rails "layered:foundation:install_devise[User]"
```

The model name argument defaults to `User`; a non-`User` name also configures `Layered::Ui.current_user_method` to match. `NON_INTERACTIVE` auto-confirms every prompt (including app-wide `authenticate_user!`). Run it interactively (`bin/rails layered:foundation:install_devise`) if they want to answer prompt-by-prompt. The task removes itself on success.

## Resetting git history (optional, separate task)

This repo is a starter, so the existing git history isn't the user's. If they want a clean slate, a separate task removes the `.git` directory and optionally re-initialises a fresh repo with an initial commit. Don't run this as part of the default setup route - only offer it if the user asks, then run:

```bash
NON_INTERACTIVE=1 bin/rails layered:foundation:reset_git
```

`NON_INTERACTIVE` auto-confirms removing `.git`, running `git init`, and the initial commit. Run it interactively (`bin/rails layered:foundation:reset_git`) if they want to answer prompt-by-prompt.
