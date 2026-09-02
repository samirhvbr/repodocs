# Versioning and commits

> **Status:** `ACTIVE` · Version 1.0 · 02/09/2026 · **Single source** for how a
> version is set and how a commit is written in this fleet.

## `version.md` is the authority

The version lives in **`version.md` at the repository root**, as a bare
`X.Y.Z` string and nothing else — no markdown, no `v` prefix, no metadata:

```
1.0.0
```

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
