---
title: Add an opencode workflow for /opencode mentions
date: 2026-10-25
paths:
  - .github/workflows/opencode.yml
  - README.md
builds_on:
  - 2026-10-18-1924-drop-the-claude-github-app-option.md
---

## Change

Added `.github/workflows/opencode.yml`, which runs opencode's GitHub action
(`anomalyco/opencode/github`) when an issue, pull request, comment or review
comment mentions `/opencode`. The model comes from the `OPENCODE_MODEL`
repository variable, defaulting to `anthropic/claude-sonnet-5-5`, with the
provider's key from one of eleven repository secrets: Anthropic, OpenAI,
OpenRouter, Together, Fireworks, Groq, Cerebras, Google (Gemini), xAI, Mistral
and OpenCode Zen. The README documents the setup.

## Why

Requested so apps made from this template can use opencode on GitHub alongside
Claude and Codex, with whichever model provider they choose. Together, Fireworks
and Groq were asked for by name, as hosts in the US, EU or UK for models made in
China; Cerebras is another, and so is OpenCode Zen, whose documentation says
all its models are hosted in the US and EU. Google, xAI and Mistral are the remaining widely
used providers with a single key.

opencode reads each provider's key from the environment variable models.dev
names for it, so a provider is supported by passing its secret through. Each
is passed explicitly rather than with something like `toJSON(secrets)`, which
would hand every secret in the repository, including deploy keys, to a process
that runs any shell command.

It acts with `GITHUB_TOKEN` (`use_github_token: true`) for the same reason
`claude.yml` does: no third-party GitHub App linked to the account, and no
`id-token: write` in a job where the agent can run any shell command.

opencode replaces a comment's text with the `prompt` input when one is given,
so the workflow only sets a prompt for new issues and pull requests, where
opencode requires one and otherwise reads the issue or pull request as context
rather than instructions. Comment-driven runs follow the comment, and
`AGENTS.md` (which opencode reads) carries the reasoning-record rule for both.

The trigger is `/opencode`, opencode's own convention, because `@opencode`
would notify the GitHub account of that name. `/oc`, opencode's other default,
is left out because it matches paths such as `/docs`.

## Ruled out

- **DeepSeek, Moonshot and Z.ai's own APIs** - we don't want the app's code and
  prompts going to China-based APIs. Their models are available through the
  US, EU and UK hosts above.
- **Amazon Bedrock, Google Vertex and Azure** - each needs several settings or
  a credentials file rather than one key; doing them properly means OIDC
  federation with the cloud account.
- **Use the Codex workflow's shape** (issues only, the workflow commits and
  pushes) - opencode's action handles branches, pushes, pull requests and the
  reply itself, and supports comments on pull requests, so wrapping it the same
  way would throw that away.
- **The opencode GitHub App** - needs `id-token: write`, which the earlier
  record removed from `claude.yml`.

## Trade-offs

OpenRouter routes a model to any provider that serves it, which can include its
maker's own API in China. Keeping requests off those needs OpenRouter's
provider settings on the account that owns the key; this workflow can't enforce
it.

Some of OpenCode Zen's free models may use prompts for training while they're
free. The workflow uses whatever `OPENCODE_MODEL` names, so it's down to whoever
sets that variable not to choose one.

opencode runs with no sandbox and network access, and the token stays in the
checkout so it can push - the same exposure as `claude.yml`. What keeps this
safe is that opencode only answers people with write access.

`@latest` and opencode's installer both float, so an upstream release can
change or break the workflow without a commit here, as `openai/codex-action@v1`
did on Ubuntu 26.04 runners.

As with Claude, CI doesn't run on opencode's pushes or pull requests until
someone else pushes, and opening a pull request needs "Allow GitHub Actions to
create and approve pull requests" enabled.

## Revisit if

opencode adds a sandbox or a way to give instructions alongside a comment, an
upstream release breaks the workflow (pin the action and opencode's version),
or apps need a provider other than these eleven, or OpenCode Zen's
documentation stops saying its models are hosted in the US and EU.

## Outcome

The workflow parses as YAML, and the prompt step was run locally for `issues`,
`pull_request` and `issue_comment` events. Not yet run on GitHub.
