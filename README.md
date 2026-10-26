# repodocs

> **Status:** `ACTIVE` · The documentation standard for the samirhvbr/Blue3
> fleet, and the place a new repository copies its skeleton from.

This repository holds no application. It holds **the norm** — what documentation
every repository in the fleet carries, what each file is for, how a version is
set and how a commit is written — plus a
[`templates/skeleton/`](templates/skeleton/) that turns the norm into a `cp -r`.

**Start with [docs/conventions.md](docs/conventions.md).** That is the single
source; everything else here either enforces it or is an example of it.

## Why it exists

The standard already existed. It just had to be inferred by opening sixteen
repositories and noticing what they had in common: `LICENSE` without an
extension in 41 of them against one `LICENSE.md`, a lowercase `version.md` in 63
against one `VERSION`, the same MIT text byte-identical in 14, the
same `X.Y.Z - description` commit rule written out separately in
five.

An inferred standard drifts. And the fleet already paid for the drift: a
`.continue/` folder full of finished work read as pending in WCUP, a brief that
read "almost done" for a product with none of its four parts built in ONLINE, a
whole design system sitting in a queue marked `NÃO ADOTADO` in INTRANET. The
cost was never untidiness — it was **a confident wrong decision by someone who
read the folder and believed it.**

The norm that fixes that was written on 29/08/2026 and lived at
`BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md`, where its own §7 admitted the
problem: a fleet-wide rule inside one product repository is invisible to whoever
opens another. It lives here now ([ADR-001](docs/decisions.md)).

## What is in here

### Root

| File | What it is for | Who reads it |
|---|---|---|
| [README.md](README.md) | This file — what the repository is and how to use it | Humans, GitHub |
| [version.md](version.md) | **The single authority on the version** — read as the first `X.Y.Z` in the file | The hooks, the release workflow, any deploy |
| [CLAUDE.md](CLAUDE.md) | Agent instructions | Claude Code |
| [AGENTS.md](AGENTS.md) | The same instructions, byte-identical below the H1 | Other agent tooling (`agents.md` standard) |
| [SECURITY.md](SECURITY.md) | The reporting path. Thin, and points at the source | GitHub, whoever reports a vulnerability |
| [CHANGELOG.md](CHANGELOG.md) | Newest first. **Each `##` heading is the commit subject** | Humans, the commit automation |
| [LICENSE](LICENSE) | MIT, English, `Copyright (c) 2026 Samir Hanna Verza` | GitHub, lawyers |
| [NOTICE](NOTICE) | Third-party attribution. **Must never contradict `LICENSE`** | GitHub, lawyers |
| [.gitignore](.gitignore) | Everything is versioned; the only exception is a secret | git |

### Directories

| Path | What it is |
|---|---|
| [docs/](docs/README.md) | **The record.** The norm, the versioning rules, the ADR log, the security guidelines, the bootstrap runbook |
| [.continue/](.continue/README.md) | **The queue.** What is still open, and whose call it is. Git-tracked on purpose |
| [.claude/](.claude/README.md) | Permission posture — the model is the user's choice, never this folder's. The deny-list always beats the allow-list |
| [templates/](templates/README.md) | The skeleton a new repository copies, with its placeholder table |
| [tools/](tools/) | `git-hooks/` (`commit-msg`, `pre-push` — enabled once per clone), `release.sh` (tag + GitHub Release for `version.md`), `fleet.sh` (`hooks` · `echo` · `check` across the fleet; dry run by default, and `check` writes nothing anywhere) and `test-fleet.sh`, its fixture |
| [.github/](.github/) | `CODEOWNERS`, `dependabot.yml` and `workflows/release.yml`. No **build/test** workflow, on purpose ([ADR-009](docs/decisions.md), narrowed by [ADR-013](docs/decisions.md)) |

## Using it

### Starting a new repository

```bash
cp -r /path/to/repodocs/templates/skeleton/. .
```

The trailing `/.` is what brings the dotfiles. Then substitute the placeholders
and enable the hooks — the full path, including the per-repo decisions the
skeleton deliberately leaves open, is [docs/runbook.md](docs/runbook.md).

### Working in this repository

```bash
git pull
git config core.hooksPath tools/git-hooks   # once per clone
```

Then: write the `CHANGELOG.md` entry, bump `version.md` in the same commit, and
commit with the entry's heading as the subject —
`1.0.1 - short description in English`. On push, the release workflow tags that
version and publishes its Release automatically. The rules, and the reasons
behind them, are in [docs/versioning.md](docs/versioning.md).

## The three rules worth knowing before you touch anything

1. **`.continue/` is the queue · `docs/` is the record · `CHANGELOG.md` is the
   history.** A document moves from queue to record the moment it describes
   something that already exists. A finished item leaves the queue.
2. **Every prescriptive document declares its status** — `ACTIVE` ·
   `HISTORICAL` · `PROPOSED` · `DEPRECATED` · `NOT ADOPTED`. One with no
   declaration is read as `ACTIVE`, which is exactly how an abandoned design
   system gets implemented.
3. **A document made stale by a change is fixed in the same pass.** A document
   that ages in silence is worse than a missing one, because it has the
   authority of being written down.

## Language

English for everything new, and for every edit to an existing document (rule in
force 03/09/2026): documents, **commit messages**, pull requests, issues, code
comments. **Nothing is bilingual** — not `LICENSE`, not a `README_br.md` pair.
**End-user-facing strings** may stay Portuguese for the Brazilian audience.
**`.continue/` drafts** use the author's working language; when the work exists
and the document moves to `docs/`, it becomes English (US). The separate rule for
Blue3 internal repositories is defined in [docs/conventions.md §8](docs/conventions.md#8-language).

**In a repository we do not own, the upstream's conventions win** — the language
and the commit shape both. Check before opening a pull request or an issue
there; when you cannot tell, English (US). See
[docs/conventions.md §8](docs/conventions.md#8-language).
