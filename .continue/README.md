# `.continue/` — the queue

> **Status:** `ACTIVE` · Last reviewed 05/09/2026, repository at `1.8.0`

Work in progress: drafts, plans under discussion, notes on things still being
built, briefings for picking the work back up later.

**The norm this folder obeys is [../docs/conventions.md](../docs/conventions.md)**
— §1 (queue vs. record) and §2 (this README is mandatory). Read it there, not
here; a second copy would be a second source of truth.

## How it works

- **Git-tracked on purpose — deliberately NOT in `.gitignore`.** Opening the
  project on another machine brings the context along, which is the whole point:
  you can *continue* from where you stopped.
- **Nothing here is source of truth.** The moment a document describes something
  that already exists, it moves to [`../docs/`](../docs/) and the permanent
  record of *when* is [`../CHANGELOG.md`](../CHANGELOG.md).
- **A finished item leaves.** It is deleted here, not ticked off — the permanent
  record of completion is the changelog. A queue holding an already-done item
  costs more than an incomplete queue: it makes the next session redo work.
- **If an item needs half a page, it is in the wrong place.** Write it in
  `../docs/` and leave one line and a pointer here.
- **In a contradiction between this folder and a document in `../docs/`, the
  document wins.**
- The **Continue** IDE also uses this folder for its own configuration.

## 1. What is left here

Nothing, in the sense of unfinished work **inside this repository**. Version
`1.0.0` shipped the whole set the plan named — the root files, `docs/`,
`.claude/`, the two hooks and `templates/skeleton/`.

Two items are genuinely open, and neither is work here:

| Item | State | Who unblocks it |
|---|---|---|
| **Stamp `LANGUAGE-RULE` and the split `RELEASES-RULE` across the fleet** — `1.8.0` split the language rule out of the Releases block and added the guest clause ([ADR-019](../docs/decisions.md)). Every repository's `CLAUDE.md` and `AGENTS.md` still carries the **old** single `RELEASES-RULE` block with the language section inside it; each needs that one block replaced by two, plus a `COMMIT-RULE` regeneration for the same boundary | **Pending — not started.** The blocks and their source files exist in [`../templates/echo-blocks/`](../templates/echo-blocks/); nothing outside this repository has been touched | **The owner**, to schedule. ~50 repositories + ~26 worktrees, each with its own bump and commit. Three traps: heading variants of the old block (the `1.5.1` sweep found them), `_quarentena/2026-09-03/` is live clones — exclude it, and since `1.9.0` **the language block has two variants** — the Blue3 internal set gets `LANGUAGE-RULE-PT` ([ADR-020](../docs/decisions.md)), and `git remote get-url origin` is what decides which. [`../tools/fleet-hooks.sh`](../tools/fleet-hooks.sh) already walks the fleet with that classification and can be read for it |
| **Retrofit pass into the sibling repositories** — turn `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` into a pointer to [`../docs/conventions.md`](../docs/conventions.md), add the pointer to each repo's own `.continue/README.md`, **and replace the bilingual `LICENSE` with the English MIT text** ([ADR-010](../docs/decisions.md)) | **Pending — not started.** Decided in [ADR-001](../docs/decisions.md) and [ADR-010](../docs/decisions.md), deliberately out of scope: no other repository has been touched | **The owner**, to schedule. It edits ~16 repositories, each with its own version bump and commit. The adoption order and the three merge rules are written at `1.8.3` in [`../templates/skeleton/docs/repodocs.md`](../templates/skeleton/docs/repodocs.md) §4 |

⚠️ **Consequences while the retrofit item is open:** two copies of the norm exist —
**this repository is the source**, and if the two disagree the copy in
BLUE3-INTRANET is the stale one. And this repository's `LICENSE` is deliberately
**no longer byte-identical to the fleet's**: it is the English MIT, the others
are still bilingual. That divergence is the correct direction and closes by
replacing them, not by reverting here.

## 2. Where things went

Every document this repository has produced was **born in `../docs/`** (§1,
third case: a survey, a contract, a runbook or an ADR does not pass through the
queue), so nothing has migrated out of here.

| Item | Where it went |
|---|---|
| **Stamp the `COMMIT-RULE` block into the fleet** — queued at `1.5.0`, done the same day | Not a document: it was a pass over the sibling repositories. The permanent record is [`../CHANGELOG.md`](../CHANGELOG.md) at `1.5.1`, and the norm it carries is [`../docs/versioning.md`](../docs/versioning.md#who-commits-and-when) |

The row is here rather than ticked off in §1, per *"a finished item leaves"*.
That is what keeps *"it misleads whoever opens it"* from simply becoming
*"nobody can find it."*

## 3. Pending decisions

| Decision | Whose | Note |
|---|---|---|
| When to run the retrofit pass (§1) | The owner | It is scheduling, not design — the design is ADR-001 |
| Whether `defaultMode` in `.claude/settings.json` stays `plan` for repositories created from the skeleton | The owner, per repository | The skeleton ships `plan` because it is the safe default to start from, not because every project must keep it. See [`../.claude/README.md`](../.claude/README.md) |

Neither blocks anything. Nothing is waiting on an answer to continue.

> **Left this section on 02/09/2026 (`1.1.0`):** *"is the bilingual `LICENSE`
> worth the lost MIT badge?"* — answered **no**. `LICENSE` is now the plain
> English MIT text and nothing in the fleet is bilingual any more
> ([ADR-010](../docs/decisions.md)). The row is deleted rather than ticked off,
> per §"a finished item leaves"; the permanent record is
> [`../CHANGELOG.md`](../CHANGELOG.md).
