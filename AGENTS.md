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

## What the task does

- Rewrites `LayeredFoundationRails`, `layered_foundation_rails`, and `layered-foundation-rails` to the new name across the codebase.
- Drops starter-only files (`LICENSE`, `NOTICE`, `TRADEMARK.md`, `CLA.md`, `template.rb`, and the setup task itself).
- Replaces `README.md` and this `AGENTS.md` file with fresh scaffolds for the user (and their agents) to build on.

## Resetting git history (optional, separate task)

This repo is a starter, so the existing git history isn't the user's. If they want a clean slate, a separate task removes the `.git` directory and optionally re-initialises a fresh repo with an initial commit. Don't run this as part of the default setup route - only offer it if the user asks, then run:

```bash
NON_INTERACTIVE=1 bin/rails layered:foundation:reset_git
```

`NON_INTERACTIVE` auto-confirms removing `.git`, running `git init`, and the initial commit. Run it interactively (`bin/rails layered:foundation:reset_git`) if they want to answer prompt-by-prompt.
