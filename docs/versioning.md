# Versioning and commits

> **Status:** `ACTIVE` · Version 1.0 · 02/09/2026 · **Single source** for how a
> version is set and how a commit is written in this fleet.

## `version.md` is the authority

The version lives in **`version.md` at the repository root**. The rule that
matters is not the file's shape but how it is read:

> **The version is the FIRST semver (`X.Y.Z`) in the file.**

Two shapes exist across the fleet and both are valid, because both read the
same under that rule:

```
1.0.0
```

```markdown
# Versão — Brasileirão Série A 2026

**Versão atual:** `0.17.1`
...
```

The bare form is what EOP, SHVIA-WEB and this repository use. The markdown form
is what the BLUE3-ISP repositories and skill-COMMITTER use, and those files
already state the rule in their own words — *"quem precisar exibir ou reportar a
versão extrai o primeiro número semver (`X.Y.Z`) encontrado aqui"* — with
`config/app.php` implementing exactly that:

```php
preg_match('/\d+\.\d+\.\d+/', file_get_contents($file), $m)
```

Some files carry more than a version — `blue3-intranet-mobile` holds `2.1.9` on
the first line and `api_min: 0.1.0` on the second. The first-semver rule reads
it correctly and the second line is left alone.

**A new repository should use the bare form** — it is the simplest thing that
satisfies the rule. Do not reshape an existing file to match: the rule already
reads it, and rewriting a `version.md` to change nothing is churn.

It is git-tracked so the bump **travels inside the commit** and the deploy
propagates it automatically. That is the whole reason it is a file and not an
environment variable: `.env` is excluded from the deploy rsync in every repo
here, so a version kept there has to be edited by hand on each server, and it
silently drifts.

**Where an app also exposes the version** (a footer, a `/version` route, a
health page), it reads `version.md`. An environment variable may exist as a
*fallback* for the case where the file is absent. It is never the authority, and
**no document may claim otherwise** — BLUE3-INTRANET's `README.md` claimed
`version.md` had been "removed in favour of `APP_VERSION`" while the file was
still there and its own `CLAUDE.md` called it the source of truth. Two documents
disagreeing about one number is how a wrong deploy gets signed off.

## Bump criteria

Bump `version.md` **in the same commit as the change it describes.** Never in a
commit of its own.

| Part | When it moves | Who moves it |
|---|---|---|
| **Z** | Documentation, wording, adjustment, correction, a new section | Every change. This is the normal case. |
| **Y** | A new locked decision (a new ADR) or a completed phase/milestone | When the decision lands |
| **X** | Reserved — a stable release | Manual, owner's call |

A product repository substitutes its own concrete triggers for the same three
slots — a new screen or a new database table is a `Z` in BLUE3-INTRANET, a new
runtime capability is a `Y` in SHVIA-DESKTOP. **The slots and the discipline are
the convention; the triggers are per-repo** and belong in that repo's
`CLAUDE.md`.

## Who commits, and when

**The agent commits.** Not "the agent leaves the tree ready and something else
picks it up" — the agent runs `git commit`, and `git push`, as the last step of
the work it was asked to do.

This has to be said out loud because for a month it was not true. The COMMITTER
skill was built precisely to take commits off the agents: from 30/07/2026 a
`.committer.yml` marker in a repository meant *"commitar e pushar não é trabalho
seu"*, and a cron cycle packaged the commit out of the changelog entry the agent
had left behind. On **03/09/2026 that skill was switched off in every repository
of the fleet** — the markers stay behind as kill-switches and nothing acts on
them any more. There is no automation waiting downstream. **If the agent does
not commit, nobody does**, and the work exists only as a dirty working tree on
one machine.

### A delivery is not delivered until it is committed

**Do not report a task as finished before the commit exists.** "Done",
"delivered", "concluded" mean the work is in `git log` — not that it is sitting
uncommitted where only the current session can see it. The commit is the last
step *of the task*, not a follow-up for someone else.

The failure this prevents is specific, and it is not hypothetical. A session
ends saying "finished"; the next one opens the repository and finds a state that
is neither the old version nor the delivered one. Work in flight is
indistinguishable from work abandoned, and the changelog entry describing the
delivery names a version that was never committed.

### The bump clause is the one a repository may override, in writing

Everything else in this section is unconditional. **The bump — "the version comes
from `version.md`, bumped in the same commit" — is not**, and it is the only
clause that bends.

A repository may stamp the version some other way **when its own documentation
says so and says why.** The written reason is the whole condition: an override
nobody wrote down is not an exception, it is a repository quietly disagreeing
with the norm, which is the failure this file exists to prevent.

The case that produced this clause is SHVIA-WEB. It stamps the version **at
merge**, not in the branch: the agent writes the changelog entry with a
`## (versão no merge) - description` placeholder, and whoever merges runs
`scripts/versao-no-merge.sh --apply`, which reads the next number from the remote
and fills it in. The reason is measured, not stylistic — **four `version.md`
collisions in a single day, between four parallel sessions.** A worktree isolates
a directory, not a number, and that repository has twenty of them live. No other
repository in this fleet has that shape, which is exactly why this is an
exception and not a change to the rule.

**Nothing else bends.** The changelog entry still comes first and still carries
the description, the subject is still `X.Y.Z - description`, the language is
still English (US), Conventional Commits prefixes are still forbidden, one
subject per commit still holds, and a delivery is still not delivered until it is
committed. A repository with no written override bumps in the commit, like
everyone else.

### One subject per commit

**A commit's subject has to describe the whole commit honestly.** The moment the
description needs an "and" to be true, it is two commits.

This is the same discipline that makes `git log --grep` worth using. A subject
reading "several improvements" is not a short description of the change — it is
an admission that the change has no single subject.

### A large delivery is split into blocks

**A complex task is committed as a series of commits grouped by subject**, each
one small enough to be described in a single line and to be read on its own.

They may share a version: bump `version.md` in the first and repeat the number
in the rest (see above — two commits carrying one version is expected, not a
mistake). **Splitting is the default** for anything non-trivial, not a measure
reserved for the enormous. The commit history is the documentation of *how* the
work was done, and one commit touching six unrelated subjects documents none of
them.

The test to run before committing: **could someone reading `git log` alone — a
year from now, without the conversation that produced the work — say what
happened, when, why, and at which version?** If not, the commit is too big or
its subject too vague, and both are fixed the same way.

## Commit message

**Mandatory format:**

```
version - short description in English
```

For example: `1.0.0 - initial documentation structure for the fleet standard`.

- **English (US)**, like everything else in the repository
  ([conventions.md §8](conventions.md#8-language)). Until 03/09/2026 this was
  the one place where Portuguese stayed; it is not any more
  ([ADR-014](decisions.md)). Messages already in history are left as they are —
  history is not rewritten.
- Descriptive enough to be found later with `git log --grep`. Explain the
  **why**, not only the what.
- **Forbidden:** Conventional Commits prefixes — `feat:`, `fix:`, `chore:`,
  `docs:`, `refactor:` — and vague messages: "ajuste", "update", "fix", "wip".
  The version, not a type prefix, is what makes this history searchable.

**Several commits may share one version.** A single delivery can be split into
commits by subject that carry the **same** version — group files by theme, bump
`version.md` in **one** of them (the first), and let the others repeat the same
number in the subject. Two commits with the same version in `git log` are
expected, not a mistake.

## The CHANGELOG heading *is* the commit message

`CHANGELOG.md` is newest-first, and each entry's H2 is literally the subject
that lands in git:

```markdown
## 1.0.0 - initial documentation structure for the fleet standard

<narrative body: what changed, why, and what it measured>
```

This is not decoration. Writing the entry first is what stops the subject from
being invented at `git commit` time: by the time the commit is made, the
sentence describing it has already been written, weighed and put where it will
be read again. It also means the changelog and the history cannot drift apart —
they are the same sentence, stored twice on purpose.

Bodies here are narrative, not bullet lists: the fleet's changelogs read as
engineering post-mortems ("how it is proven", "where it came from", "measured",
"what is left"), which is why a two-year-old entry is still worth reading.

## Tags and Releases

**Every version gets a git tag named after it, and a published GitHub Release
on top of that tag.**

GitHub never infers a version from a commit subject. A repository whose history
is full of `2.110.161 - …` still shows **"No releases published"**, and
`git diff 2.110.160..2.110.161` fails, because neither name exists as a ref.
That was the state of all 54 repositories in this fleet until 02/09/2026: zero
Releases, and three tags between them.

The tag is what pins a version number to the exact code it named. Without it the
number is a string in a commit message; with it, a bad deploy has something to
roll back **to**.

### The rule, in one line

> **The `version.md` on GitHub equals the Releases on GitHub.**

The local checkout does not enter the calculation. It can be behind, ahead, or
mid-work, and none of that is published — GitHub cannot tag a commit it does not
have, and a Release for a version nobody can fetch is a lie.

So the authority is the **remote default branch**, not the working tree.
`tools/release.sh` reads `version.md` from `origin/<default>` and tags that
commit; when the remote branch is not resolvable — the CI case, where `HEAD`
*is* the pushed commit — it falls back to `HEAD`. If the local file disagrees, it
says so and publishes the remote's number anyway.

**What that looks like in practice.** An agent opens a PR at `1.3.25`. Nothing is
published while it is a PR — the version is not on the default branch yet. The
moment it merges, the push to `master` touches `version.md`, the workflow fires,
and the Release becomes `1.3.25`. Merge is the event; nothing has to be
remembered.

Measured while writing this: `sshvterm-desktop` had `1.3.19` locally and
`1.2.80` on `origin/master` (8 unpushed commits), and `shvia-web` had
`2.110.154` locally and `2.110.161` on the remote. In both, the Release that
belongs on GitHub is the remote's number.

### The bump and the Release are one act

**A commit that bumps `version.md` is not finished until that version has a
Release.** Not "later", not "when someone remembers" — the same push.

That is what the workflow is for: it fires on any push touching `version.md`, so
the bump *carries* the Release with it and nobody has to do a second thing. If
you bump by hand and the workflow is unavailable, `./tools/release.sh` closes it
in one command.

**The `Latest` badge belongs to the version `version.md` names.** Not to the
newest by date, not to the last one some run happened to create. This is not a
detail: a viewer reads the badge as *"this is the current version"*, and a badge
pointing at an older release says something false about the project.

Measured on 02/09/2026, and it is the reason this section exists: a backfill
started while `sshvterm-desktop` said `1.2.80`, a push moved the file to
`1.2.81` mid-run, the Release for `1.2.81` was created correctly — and the
backfill then stamped `Latest` on `1.2.80`, because it was still working from
the version it had read at startup. `shvia-web` showed the same shape with
`2.110.162` in the file and the badge on `2.16.38`.

Two fixes came out of it, both in `tools/release.sh`:

1. `--latest` is applied **only to the version `version.md` names**, never to
   "the last one this run touched".
2. Every run ends by **re-reading the remote's `version.md` and moving the badge
   there** if it drifted. That makes any run, at any time, self-healing:

   ```
   release.sh: badge Latest movido de 1.2.80 para 1.2.81 (version.md manda)
   ```

So the check for "is this repo correct?" is one command that also fixes it:

```bash
./tools/release.sh          # idempotent; publishes what is missing, fixes the badge
```

### The naming

| Thing | Value | Example |
|---|---|---|
| Tag | The version, **exactly as `version.md` holds it** — no `v` prefix | `2.110.161` |
| Release title | The same string | `2.110.161` |
| Release notes | The `CHANGELOG.md` section for that version | — |

The tag is byte-for-byte what `version.md` says, so there is nothing to
translate between the file, the tag and the Release.

> **Three older tags in the fleet carry a `v`** — `v0.15.0` in
> `brasileirao-a-2026` and one in SHVIA-DESKTOP. They are **left alone as
> history**; new tags are bare. What was corrected instead are the two
> `version.md` files whose text still instructed the `v` form, so no document is
> left contradicting the artefact ([ADR-011](decisions.md)).

### Where the notes come from

In order, first hit wins:

1. **The `CHANGELOG.md` section for that version** — from its heading down to
   the next heading *at the same level or higher*, so the entry keeps its own
   `###` subsections, which is where the substance is. Both fleet heading shapes
   are matched: `## 1.1.0 - título` and `` ### `0.17.0` — 2026-08-24 — título ``.
2. **The commit subjects carrying that version**, when there is no matching
   section. EOP has no `CHANGELOG.md` at all, so this is not a theoretical path.
3. **GitHub's generated notes**, as the last resort.

### Who creates it

Two owners, both guarding on the same question — *does this tag already exist?*
— so whichever runs first wins and the other is a no-op:

| Owner | When | Covers |
|---|---|---|
| **`.github/workflows/release.yml`** | Every push that touches `version.md` | Every push, whoever made it — by hand or by an agent |
| **`tools/release.sh`** | Run by hand | The same logic, for closing it now instead of waiting for Actions, and for a backfill |

There used to be a third owner: the COMMITTER skill published the Release right
after its own push succeeded. It was switched off across the fleet on
03/09/2026 (see [Who commits, and when](#who-commits-and-when)), and the
workflow — which was already carrying most of the fleet, because the marker was
`enabled: false` in BLUE3-INTRANET, SHVIA-DESKTOP and SHVIA-WEB and
`push: false` in EOP — now carries all of it. That the design never depended on
the skill is why removing it cost nothing.

Neither owner ever *decides* a version. Both copy the number the agent already
wrote into `version.md`. Deciding the version is the agent's judgement and
nothing else's — that was true when an automation did the committing, and it is
more obviously true now that the agent does.

### `tools/release.sh`

The one implementation both owners call — the workflow runs this script rather
than reimplementing the rules, because two copies of one rule is how a rule ends
up with two versions, one of them wrong.

```bash
./tools/release.sh --dry-run              # print the table, create nothing
./tools/release.sh                        # tag + Release for the current version
./tools/release.sh --backfill --dry-run   # the whole history, as a table
./tools/release.sh --backfill             # the whole history, for real
```

It is **idempotent and resumable by construction** — anything already published
is skipped, so re-running is free and an interrupted run simply continues. It
throttles, and it **stops and reports** when the API budget runs low rather than
exhausting it.

In `--backfill`, for each distinct version the tag points at the **last** commit
that carried it — the finished state of that version, not its first commit.
Several commits sharing one version is expected and allowed (see above), so
"first commit of the version" would tag an unfinished state.

---

## The hooks

Two hooks live in [`../tools/git-hooks/`](../tools/git-hooks/). They are **not
active on clone** — enable them once, per clone:

```bash
git config core.hooksPath tools/git-hooks
```

| Hook | What it checks | Why there |
|---|---|---|
| `commit-msg` | The subject matches `X.Y.Z - <comment>`; rejects Conventional Commits prefixes, vague and too-short comments | It is the only moment the message exists and the commit does not |
| `pre-push` | `version.md` against `origin/<default branch>`: rejects a duplicate, rejects a decrease | It is the only hook that sees the **remote** — and `commit-msg` provably does not run during a rebase, which is how duplicate versions get born |

Two deliberate design choices, both load-bearing:

- **`pre-push` runs no test suite.** A push that waits four minutes becomes
  `--no-verify` the following week, and then the control is dead. It asks two
  questions about one line of one file.
- **With no reachable remote it degrades with a warning, never a refusal.** A
  guard that blocks work when it cannot measure is a guard that gets switched
  off.

Escape hatch, declared in both: **`REPODOCS_NO_HOOK=1`** (the skeleton names it
`PROJECT_NO_HOOK` and expects you to rename it to your project's prefix).

An escape hatch is not a loophole — it is what keeps the hooks installed. A
guard with no declared bypass gets bypassed with `--no-verify`, which bypasses
*every* guard at once.
