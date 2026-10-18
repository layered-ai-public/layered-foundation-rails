---
title: Drop the Claude GitHub App option from the Claude workflow
date: 2026-10-18
paths:
  - .github/workflows/claude.yml
  - README.md
---

## Change

`claude.yml` always acts with the workflow's `GITHUB_TOKEN`. The
`CLAUDE_GITHUB_APP` repository variable, which switched it to the Claude GitHub
App, is gone, along with the job's `id-token: write` permission that the app's
OIDC token exchange needed.

## Why

We don't want the Claude GitHub App linked to our GitHub account. Nothing else
needs it now: the Codex workflow and claude-review-action both use
`GITHUB_TOKEN`. The option kept `id-token: write` on every run even when unused,
in a job where Claude can run any shell command, so it could mint an OIDC token
for the repository. GitHub doesn't allow a job's permissions to depend on a
variable, so the permission could only go if the option went with it.

## Ruled out

- **Keep the option and drop only `id-token: write`** - anyone who turned the
  option on would get a workflow that fails when fetching the app token.
- **Keep both** - leaves an unused OIDC permission on every run for an option
  we don't use.

## Trade-offs

Pushes and pull requests Claude makes don't trigger CI, because GitHub doesn't
start workflows for `GITHUB_TOKEN` events. Someone has to push to the branch,
or close and reopen the pull request, to run CI on Claude's work. Apps made from
this template lose the option to avoid that by installing the app.

## Revisit if

Running CI by hand on Claude's work becomes a real cost, or another way to
authenticate as a separate identity (such as a Layered GitHub App token) becomes
available to the workflow.
