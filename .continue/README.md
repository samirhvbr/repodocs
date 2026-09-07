# `.continue/` — the queue

> **Status:** `ACTIVE` · Last reviewed 07/09/2026, repository at `1.10.3`

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
- **A finished item leaves — and *finished* means the thing exists.** It is
  deleted here, not ticked off; the permanent record of completion is the
  changelog. A queue holding an already-done item costs more than an incomplete
  queue: it makes the next session redo work.
- **Nothing leaves for any other reason.** Not length, not language, not a
  session ending, not an agent who would have written it differently. **To
  produce an item is to make the thing exist**, and deleting the document is the
  last step of the commit that carries the work — never a step of its own.
- **If an item needs half a page to describe something that already exists**, it
  is in the wrong place. Write it in
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
| **Stamp the four echo blocks across the fleet** — `QUEUE-RULE`, `LANGUAGE-RULE`, the split `RELEASES-RULE` and `COMMIT-RULE`. Measured 07/09/2026 across 54 repositories: `QUEUE-RULE` in **1**, `LANGUAGE-RULE` in **1**, and most still carry the **old** single `RELEASES-RULE` with the language section inside it. `QUEUE-RULE` is the urgent one — it is the rule that failed in `notes`, and 35 repositories do not mention `.continue/` at all | **Open, and now one command.** `./tools/fleet.sh echo --apply` does all four, replacing each block whole between its markers and choosing the `-PT` variant by the owner on `origin`. Proven on `KIDS/KIDS-TD` at `0.20.9`; `notes` was stamped by hand before the tool existed | **The owner**, to schedule. Two traps the tool already handles: a block edited in place is replaced heading and all, and `_quarentena/` is live clones and is excluded. `./tools/fleet.sh check` is what says when it is done |
| **Move the changelog out of `version.md` in 23 repositories** — the standard's changelog is `CHANGELOG.md`, whose `## X.Y.Z - description` heading *is* the commit subject ([conventions.md §3](../docs/conventions.md)). 23 fleet repositories keep theirs as a section inside `version.md` instead, in a per-repo heading style (`### \`X.Y.Z\` — date — subject`), which is why `fleet-hooks.sh` writes no entry there | **Open.** Measured at `1.9.4`; the list is what `./tools/fleet-hooks.sh` prints under *CHANGELOG LIVES INSIDE version.md* | **The owner**, to schedule. It is a real migration, not a copy: the entries have to be reshaped, `version.md` has to stop describing a section it no longer holds, and a repository that also documents the old location in its `CLAUDE.md` needs that fixed in the same pass. Creating the second file automatically was tried at `1.9.3` and reverted at `1.9.4` — two changelogs in one repository drift, and this one decides what a version means |
| **Refresh `tools/release.sh` across the fleet** — `1.9.1` fixed it resolving the repository through `gh repo view` with no argument, which in a fork answers the **upstream** and publishes a Release into somebody else's repository. Every copy distributed before `1.9.1` carries the defect | **Open.** Fixed here and in the skeleton; `000/hermes-agent` was patched by hand because it is the one repository with a second remote today | **Closed by the same command as the hooks.** Since `1.11.0` the `hooks` mode rewrites `tools/release.sh` too, wherever the copy carries the `repodocs:tool` marker — so `./tools/fleet.sh hooks --apply` fixes it everywhere in the same pass |
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
