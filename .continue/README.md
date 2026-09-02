# `.continue/` — the queue

> **Status:** `ACTIVE` · Last reviewed 02/09/2026, repository at `1.0.0`

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

One item is genuinely open, and it is not work here:

| Item | State | Who unblocks it |
|---|---|---|
| **Retrofit pass into the sibling repositories** — turn `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` into a pointer to [`../docs/conventions.md`](../docs/conventions.md), and add the pointer to each repo's own `.continue/README.md` | **Pending — not started.** Decided in [ADR-001](../docs/decisions.md), deliberately out of scope for `1.0.0`: no other repository was touched | **The owner**, to schedule. It edits ~16 repositories, each with its own version bump and commit |

⚠️ **Consequence while that item is open:** two copies of the norm exist. **This
repository is the source.** If the two disagree, the copy in BLUE3-INTRANET is
the stale one.

## 2. Where things went

Nothing has left this folder yet — `1.0.0` is the first release, and every
document it produced was **born in `../docs/`** (§1, third case: a survey, a
contract, a runbook or an ADR does not pass through the queue).

When something does move out, it gets a row here with a relative link. That is
what keeps *"it misleads whoever opens it"* from simply becoming *"nobody can
find it."*

## 3. Pending decisions

| Decision | Whose | Note |
|---|---|---|
| When to run the retrofit pass (§1) | The owner | It is scheduling, not design — the design is ADR-001 |
| Whether `defaultMode` in `.claude/settings.json` stays `plan` for repositories created from the skeleton | The owner, per repository | The skeleton ships `plan` because it is the safe default to start from, not because every project must keep it. See [`../.claude/README.md`](../.claude/README.md) |

Neither blocks anything. Nothing is waiting on an answer to continue.
