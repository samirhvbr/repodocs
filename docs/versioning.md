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

## Commit message

**Mandatory format:**

```
versão - comentário em português
```

For example: `1.0.0 - estrutura inicial de documentação do padrão da frota`.

- The comment is **in Portuguese** — one of the only two deliberate carve-outs
  to the English rule ([conventions.md §8](conventions.md#8-language)).
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
## 1.0.0 - estrutura inicial de documentação do padrão da frota

<narrative body: what changed, why, and what it measured>
```

This is not decoration. It is what lets a commit automation build the message
without inventing one, and it means the changelog entry — not the commit — is
the handoff artefact between an agent and whoever commits.

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
| **`.github/workflows/release.yml`** | Every push that touches `version.md` | Every push, whoever made it — by hand, by an agent, or by the cron cycle |
| **The COMMITTER skill** | Right after its own push succeeds | Its participating repos, immediately, without waiting for Actions |

The workflow is what actually delivers this today: the COMMITTER marker is
`enabled: false` in BLUE3-INTRANET, SHVIA-DESKTOP and SHVIA-WEB, and
`push: false` in EOP — a skill-only design would have left most of the fleet
without Releases.

Neither owner ever *decides* a version. Both copy the number the agent already
wrote into `version.md`, which is what keeps COMMITTER's inviolable
"nunca bumpa versão" rule intact.

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
