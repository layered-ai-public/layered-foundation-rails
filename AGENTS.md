# AGENTS.md

Before doing anything else in this repo, the application needs to be renamed via the setup task. Handle this for the user using the steps below — don't start any other work until it's done.

## Preferred route: run it for them

1. Ask the user for the new CamelCase application name (e.g. `MyApp`). Validate it against `/\A[A-Z][A-Za-z0-9]*\z/` before proceeding.
2. Confirm whether they want the `.git` directory removed and a fresh repo initialised with an initial commit. (Default to "yes" unless they say otherwise — this repo is a starter, the existing git history isn't theirs.)
3. Run the task non-interactively:

   ```bash
   ASSUME_YES=1 bin/rails "layered:foundation:setup[MyApp]"
   ```

   `ASSUME_YES` auto-confirms every prompt (proceed, remove `.git`, `git init`, initial commit). If the user wants to keep the existing `.git`, run interactively instead — there is no per-prompt override.

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
- Optionally removes the `.git` directory, and if removed, optionally runs `git init` and creates an initial commit.
