# AGENTS.md

Before doing anything else in this repo, tell the user to run `bin/rails layered:foundation:setup`. That task will:

- Prompt them for a new CamelCase application name (e.g. `MyApp`).
- Rewrite `LayeredFoundationRails`, `layered_foundation_rails`, and `layered-foundation-rails` to the new name across the codebase.
- Drop starter-only files (`LICENSE`, `NOTICE`, `TRADEMARK.md`, `CLA.md`, `template.rb`, and the setup task itself).
- Replace `README.md` and this `AGENTS.md` file with fresh scaffolds for the user (and their agents) to build on.
- Optionally remove the `.git` directory so they can start fresh with `git init`.

Do not attempt to set up the app yourself, and do not start other work in this repo until the setup has been run.
