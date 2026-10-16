---
name: reasoning
description: Reads and writes the reasoning records in docs/reasoning - why each change to this app was made, what was ruled out, the trade-offs accepted and when to revisit. Use before changing any code (to check what earlier changes decided in that area) and after making a change (to write or update its record). Not needed for answering a question that changes no code.
metadata:
  author: layered.ai
  version: "1.0"
---

# reasoning

Every change to this app is a **layer**: the code, plus a record of why it was made.
Git records which lines changed; the reasoning record says why, what else was weighed,
what was knowingly given up, and what would justify changing course. The next change -
yours or another agent's - builds on those decisions instead of guessing at them or
quietly undoing them.

Records live in `docs/reasoning/`, one Markdown file per change, committed on the same
branch as the code they explain. They are reviewed in the same pull request and merge
with it. Layered Cloud reads them from there.

## Before changing code: read

1. List `docs/reasoning/` and read each record's front matter. It's short, so this is
   cheap.
2. Read in full every record whose `paths` overlap the files you're about to change, or
   whose title is about the same thing.
3. Before relying on a record, check no other record names it in `supersedes`. Merged
   records are never edited, so the old one won't say it has been replaced.
4. Treat what they decided as settled. Don't bring back something a record ruled out,
   and don't "fix" one of its **Trade-offs** - those downsides were accepted on purpose.
   Change course only when the task says to, or when a record's **Revisit if** condition
   now holds.
5. If the task does reverse an earlier decision, do it openly: write a new record, name
   the old one in `supersedes`, and say in **Why** what has changed since - ideally the
   old record's **Revisit if** condition.

If the repository keeps other written records of past decisions - design notes, decision
logs, docs written before these records began - read the ones for the same area too.
They're a different format, but just as settled.

If a record and the code disagree, the code is what runs - mention the mismatch rather
than silently "fixing" either.

## After changing code: write

One record per change, which is one per pull request. Every commit on the change's
branch updates that record: a follow-up on the same branch edits it rather than adding
another. Write it in the same run as the code, from the work itself - the request, what
you found, what you tried - not afterwards as a summary of the diff.

Never edit a record that has already merged. A later change that reverses it gets its
own record with `supersedes`.

File: `docs/reasoning/YYYY-MM-DD-short-slug.md`, dated the day the change was made, the
slug from the title. If that file already exists for a different change, add `-2`
(then `-3`). No number: Layered numbers a layer by its pull request once it merges,
which doesn't exist yet while you're writing.

```markdown
---
title: Move background jobs to Solid Queue
date: 2026-10-14
paths:
  - config/queue.yml
  - config/environments/production.rb
  - app/jobs/
request: https://github.com/acme/shop/issues/142
enforced_by:
  - test/config/no_redis_test.rb
supersedes: 2026-03-02-use-sidekiq-for-jobs.md
---

## Change

Replaced Sidekiq with Solid Queue. Removed the Redis dependency from production.

## Why

The app runs on a single node. Redis was only there for jobs, and it added cost,
another thing to monitor, and another thing that could fail.

## Ruled out

- **Keep Sidekiq** - fine technically, but keeps Redis around for one job.
- **GoodJob** - solid option, but Solid Queue is the Rails 8 default and fits the
  rest of the stack.

## Trade-offs

Jobs now share the SQLite database with the app, so a burst of jobs competes with web
requests for writes. Acceptable at current volume.

## Revisit if

The app runs on more than one server, or job throughput regularly passes a few hundred
a minute.

## Outcome

Tests pass; job latency unchanged in development.
```

### Front matter

- `title` - what the change does, in the imperative, under 80 characters.
- `date` - `YYYY-MM-DD`.
- `paths` - the areas the change was about: directories (trailing `/`) and the few
  files that matter, not every file touched. Start from `git diff --name-only` and
  collapse it. This is how the next change finds the records that concern it, and
  areas stay accurate when files move within them.
- `request` - optional; a link to what asked for the change, such as the issue.
- `enforced_by` - optional; tests or lint rules that fail if the decision is undone.
  A record is advice; these are what actually hold the line. Add one when a decision
  is easy to undo by accident.
- `supersedes` - optional; the filename of an earlier record this one reverses.

Don't add a commit SHA: the record is in the same commit as the code, so it can't name
it, and squash merges change it anyway. Layered links the merge commit itself.

### Sections

- **Change** - what is different now, in a sentence or two. The diff has the detail.
- **Why** - the problem and the reason: the constraint, the bug, the request. This is
  the part nobody can recover later.
- **Ruled out** - alternatives you actually weighed, each with why not. Don't invent
  options to fill it.
- **Trade-offs** - downsides accepted in choosing this, so a later change doesn't
  mistake them for bugs.
- **Revisit if** - the concrete conditions under which this should be reconsidered.
- **Outcome** - what you checked: tests, a manual run, a measurement. Only what you
  verified. Layered adds deploy outcomes itself; never write them back here.

**Change** and **Why** are always required. The other four are for changes that
involved a decision: leave a section out rather than pad it. A typo fix is two
sections:

```markdown
---
title: Fix the home page title's spelling
date: 2026-10-16
paths:
  - app/views/pages/home.html.erb
---

## Change

Corrected "Wellcome" to "Welcome" in the home page title.

## Why

Typo reported in the request.
```

Plain, specific sentences; no headings beyond these six.
