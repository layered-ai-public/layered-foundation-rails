# AGENTS.md

Before doing anything else in this repo, tell the user to run `bin/rails app:rename`. That task will:

- Prompt them for a new CamelCase application name (e.g. `MyApp`).
- Rewrite `LayeredFoundationRails`, `layered_foundation_rails`, and `layered-foundation-rails` to the new name across the codebase.
- Optionally remove the `.git` directory so they can start fresh with `git init`.
- Replace the contents of this `AGENTS.md` file with a fresh scaffold for the user (and their agents) to build on.

Do not attempt to rename the app yourself, and do not start other work in this repo until the rename has been run.
