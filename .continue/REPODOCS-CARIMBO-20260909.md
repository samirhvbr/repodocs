# The stamping chain — nine items, and the decisions they wait on

> **Status: SPEC. Nothing here is implemented.** It proposes; the owner decides item by
> item, and D1–D7 below are the decisions that unblock them. Written 09/09/2026 after a
> day in which six defects, four false findings and two inert guards all had one shape.

## The shape they share

Every failure this document collects looks the same from inside:

> **The instrument answered something plausible, and nobody checked the trigger.**

The `commit-msg` hook is correct and is never called on `rebase --continue`. `--auto`
is the right flag and waits for nothing when no check is required. A ratchet reads
`max(cru, pt)` and stays green while debt grows underneath. None of them failed loudly.

That is why these are one document rather than nine tickets: the fix for each is
mechanical, and the reason they were all open at once is that **the fleet's guards are
content without trigger**.

> **Items 7–9 were added on the same day, by the session that held the data for D4.** They
> are not a second opinion on 1–6: none of the six touches *who assigns a version number*,
> and three of the day's failures were exactly that. Nothing above was changed except D4,
> which said the measurement lived elsewhere — it now says what the measurement showed.

---

## The items

### 1. Stamp the four echo blocks across the fleet
`QUEUE-RULE`, `LANGUAGE-RULE`, the split `RELEASES-RULE` and `COMMIT-RULE`. Measured
07/09/2026 over 54 repositories: `QUEUE-RULE` in **1**, `LANGUAGE-RULE` in **1**, most
still carrying the old single `RELEASES-RULE`. One command does it:
`./tools/fleet.sh echo --apply`. **Waits on: D1.**

### 2. Move the changelog out of `version.md` in 23 repositories
The standard's changelog is `CHANGELOG.md`, whose `## X.Y.Z - description` heading *is*
the commit subject. 23 repositories keep theirs inside `version.md`, which is why
`fleet-hooks.sh` writes no entry there. A real migration, not a copy. **Waits on: D2.**

### 3. Refresh `tools/release.sh` across the fleet
Every copy distributed before `1.9.1` resolves the repository through `gh repo view` with
no argument — in a fork that answers the **upstream** and publishes a Release into someone
else's repository. Closed by the same `./tools/fleet.sh hooks --apply`. **Waits on: D1.**

### 4. 🔴 `commit-msg` is not invoked on `rebase --continue`
Measured 09/09/2026 with the fleet's own hook plus a log line before every early exit.
`commit`, `--amend`, `cherry-pick --continue` and `rebase -i` (reword) all invoke it and
all block. **`rebase --continue` never calls it** — and that is the step a person is on
precisely while renumbering, which is how a commit landed saying `1.4.33` with
`version.md` at `1.4.34`. `merge --continue` calls it and exits by design
(`commit-msg:29`, `MERGE_HEAD`) — **a declared exemption, not the bug**.
Full table: [`ACHADO-commit-msg-no-rebase-20260909.md`](ACHADO-commit-msg-no-rebase-20260909.md).
**Waits on: D3.**

### 5. 🔴 One tag can carry two Releases
Same family: the Release side of the stamping chain has a race the guard does not cover.
`release.yml` fires on every push and calls `tools/release.sh`; `RELEASES-RULE` tells the
operator to run the same script right after pushing. Both decide by asking whether the
Release exists, so within those seconds **both ask before either answers**, and the GitHub
API does not refuse a second Release on an existing tag.

Measured 09/09/2026 here: `1.14.2` — the version where the script was run right after the
push — carries **two** Releases on one tag; `1.14.0`, `1.14.1`, and the two controls
`1.14.3` and `1.14.4` carry **one** each.
Full record: [`ACHADO-duas-releases-mesma-tag-20260909.md`](ACHADO-duas-releases-mesma-tag-20260909.md).
**Decided in `1.14.5`, not applied — see D4.**

### 6. 🔴 Branch protection is absent in 8 of 9 repositories
🔬 Measured 09/09/2026, and it is what turns *"CI green before merge"* from a rule into a
mechanism:

| repository | default branch | protection |
|---|---|---|
| `shvia-web` | `master` | ❌ none |
| `shvia-desktop` | `master` | ❌ none |
| `repodocs` | `master` | ❌ none |
| `shvia-rota` | `main` | ❌ none |
| `shvia-site` | `main` | ❌ none |
| `shvia-code` | `master` | ❌ none |
| `blue3-intranet` | `master` | ❌ none |
| `ai-benchmark` | `master` | ❌ none |
| **`sshvterm-desktop`** | `master` | ✅ `tests,servidor,build` |

**The consequence, proven live the same day:** `gh pr merge --auto` waits only for
**required** checks. With no protection there are none, so `--auto` merges immediately —
observed on `shvia-desktop#3`, which merged instantly and reported `auto=false`. Until
protection exists, every defence against a blind merge is human discipline, and that
discipline failed on the day it was written down, with the person who wrote it.

⚠️ **The cost is real and the spec does not hide it.** Making `test` required means every
PR waits ~10 minutes. Making `assunto` required means nobody merges without stamping —
which is the desired behaviour, but enforced rather than remembered. **Waits on: D5, D6.**

---

### 7. 🔴 The version-carrier guard runs after the commit, and the rollout does not trigger it
**M1 of [`../../SHVIA/.continue/REVISAO-20260908.md`](REVISAO-20260908.md), unresolved.**

`build.rs` (code), `sync-version.mjs --verificar` (mobile, desktop) and
`sync-version.sh --verificar` (code) all **exist** and all **work** — in CI, after the push.
The `repodocs` `commit-msg` checks one file. Measured result: **three red `master` in one
day, from the same gesture**.

It belongs in this document and not only in that review, because it is the same sentence as
items 4 and 5 with a different subject: **the guard is correct and the trigger is late.**
Three shapes were named there; the one that closes the path actually walked is `fleet.sh`
calling the repository's own synchroniser before committing, and **refusing to bump** when a
repository has more than one carrier and no synchroniser. **Waits on: D8.**

### 8. 🔴 Two repositories stamp in the branch, one stamps at merge, and the fix was never ported
Measured 09/09/2026 across the eight SHVIA repositories: **`scripts/versao-no-merge.sh`
exists in `SHVIA-WEB` and in nothing else.**

| repository | how it stamps |
|---|---|
| `SHVIA-WEB` | **at merge** — the branch carries `## (versão no merge)` and the script stamps on the way in |
| the other seven | **in the branch**, per the `COMMIT-RULE` default |

`SHVIA-WEB` moved to stamp-at-merge on 29/08/2026 after **four version collisions in a
single day between four sessions**, and its `CLAUDE.md` records the reasoning: *"a worktree
isolates a directory, not a number"*. `SHVIA-DESKTOP` still stamps in the branch, and on
09/09 two fronts forked from `1.4.30` and both stamped `1.4.31` — which is what sent
somebody into the `rebase --continue` that produced item 4.

🔬 **And it happened again while this very item was being written**, in `repodocs` itself:
two sessions stamped `1.14.5`, and then `1.14.6`. The `pre-push` hook refused both times
(*"version X is already on master"*) and nothing was forced — **the guard worked**. But it
refuses at the *end*, after the changelog entry is written and the commit is made, and the
recovery is a renumber by hand: exactly the gesture that item 4 shows is unguarded.

⚠️ **This is not a recommendation to port `versao-no-merge.sh` to nine repositories.** It is
a 300-line script serving a repository with 26 PRs in one day; six of the nine merge a
handful of times a week and would pay its complexity for a collision they never have. The
decision is *which repositories have the traffic that justifies it*. **Waits on: D9.**

### 9. The six method lessons live in one repository, and the other eight do not have them
`SHVIA-WEB/AGENTS.md` carries method sections — the mechanical-guard rule, *"I violate what
I demand"*, search by content rather than by path, the verification on the silent side of a
pair, guard = content **and** trigger, and the social verification. They are fleet-wide
lessons written in one place.

🔬 **The premise this item started from was wrong, and the measurement is the item.** The
worry was that `fleet.sh echo` would overwrite them. It cannot: `stamp_block()` replaces
only what lies between the `<!-- NAME:repodocs -->` markers, and in that file (1482 lines)
the markers sit at 1342–1402 and 1438–1482 while every method section is above 1342.

**The real risk is non-arrival, not overwriting** — and it does not close by itself, because
nothing carries them and no check reports their absence. The two shapes are not equivalent:
a fifth echo block makes them regenerate everywhere and turns method into boilerplate nobody
re-reads; a document in `docs/` that the agent files point at keeps them one text and makes
them a hop away. **Waits on: D10.**

---

## Decisions

| # | Decision | What it unblocks | Cost of saying yes |
|---|---|---|---|
| **D1** | Run `./tools/fleet.sh echo --apply` and `hooks --apply` over the fleet | items 1 and 3 | one pass, 54 repositories, `_quarentena/` excluded by the tool |
| **D2** | Schedule the `version.md` → `CHANGELOG.md` migration | item 2 | 23 repositories, entries reshaped by hand; the automatic version was tried at `1.9.3` and reverted at `1.9.4` |
| **D3** | Which shape closes the `rebase --continue` gap | item 4 | see D3a/D3b below — they are not equivalent |
| **D3a** | `post-rewrite` hook | — | it runs **after** the rewrite: it can report, never refuse. A guard that reports is a different promise |
| **D3b** | Move the check into `pre-push` (which already exists and already compares versions) | — | catches it later, but **refuses** — and `pre-push` is the one gate the fleet already treats as the human's entry point |
| **D4** ✅ | **Decided `1.14.5`: change the instruction, not the code.** `RELEASES-RULE` loses *"running it is always safe"* and gains the measured rule — the workflow covers the push; running the script by hand right after duplicates. Applying it is one template edit + a fleet pass | item 5 | nothing new: it rides the D1 rollout. The two refused alternatives are recorded in the finding so they are not re-opened without new evidence |
| **D5** | Which checks become required, **per repository** | item 6 | `test` = ~10 min per PR · `assunto` = no merge without stamping · `sshvterm-desktop` already runs three and is the only precedent |
| **D6** | Whether protection also blocks direct push to the default branch | item 6 | it would end "commit and push to master", which is the fleet's current flow in 8 of 9 repositories — this is the expensive half, and the spec does **not** recommend it by default |
| **D7** | Whether `.continue/` items of this class stay per-repository or centralise here | all nine | centralising makes them visible; it also moves them away from the repository that has to act |
| **D8** | Where the version-carrier guard runs, and whether `fleet.sh` **refuses** to bump a repository with multiple carriers and no synchroniser | item 7 | the refusal is one more case in a script that already refuses several; the cost is a bump that stops working until somebody adds the synchroniser — which is the point |
| **D9** | **Which** repositories move to stamp-at-merge — not whether | item 8 | 🔴 *this is the expensive one and the spec does not recommend "all nine".* `versao-no-merge.sh` is ~300 lines serving a repository with 26 PRs in a day; six of the nine would pay that complexity for a collision they never have. Ordered by measured traffic: `SHVIA-WEB` has it, `SHVIA-DESKTOP` is the one with a collision on record, and the rest have none |
| **D10** | Whether the method lessons become a **fifth echo block** or a document in `docs/` that the agent files point at | item 9 | the block regenerates everywhere and turns method into boilerplate nobody re-reads; the pointer keeps one text and costs a hop. **Not equivalent, and the spec leans to the pointer** |

🔴 **D6 and D9 are the two to read twice.** Both change how people work rather than what a script does, and both are the kind of decision that looks small in a table and is not.

**D6:** Requiring status checks and blocking direct push are
separate switches. The first makes the merge wait; the second changes how everyone works.
The measured problem — a merge with a pending check — is fixed by the first alone.

---

---

## Phases

The order is not preference: each phase removes a way the next one could go wrong. Running
them out of order is how a rollout repeats the defect it was meant to close — which already
happened once, and is why item 1 waits on nothing but D1 while item 3 rides with it.

### Phase 0 — the guards that must exist before anything is rolled out
**D8, D3.** Nothing here touches nine repositories; it makes the tools safe to point at
them.

- `fleet.sh` calls the repository's synchroniser before committing a bump, and **refuses**
  where there are multiple carriers and no synchroniser (D8).
- The `rebase --continue` gap closes in whichever shape D3 picks (D3a reports, D3b refuses —
  and they are different promises).

🔴 **Why first, and it is measured:** a rollout bumps a version in every repository it
touches. With item 7 open, the rollout **is** the gesture that produced the three red
`master`. Phase 0 exists so the fleet pass is not the thing that breaks the fleet.

### Phase 1 — the fleet pass
**D1, and D4 rides in it.** `./tools/fleet.sh echo --apply` and `hooks --apply`: the four
echo blocks, the `release.sh` refresh, the hooks. The `RELEASES-RULE` edit decided in D4 is
one line in `templates/echo-blocks/RELEASES-RULE.md` and must land **before** this pass, or
the fleet gets the false sentence stamped into nine repositories on purpose.

Closes items 1, 3 and 5. `./tools/fleet.sh check` is what says when it is done.

### Phase 2 — the decisions that change how people work
**D5, D6, D9.** Branch protection per repository, and stamp-at-merge for whichever
repositories D9 names. Deliberately after the pass: protection that requires a check makes
every PR wait, and turning it on while the fleet is mid-rollout means the rollout waits too.

🔴 **D6 (blocking direct push) is separable from D5 (required checks) and the spec does not
bundle them.** The measured problem — a merge with a pending check — is closed by D5 alone.

### Phase 3 — the migrations that are real work
**D2, D10.** The `version.md` → `CHANGELOG.md` migration in 23 repositories, and the method
lessons finding a home. Last because neither blocks anything and both are hand work: the
changelog entries have to be reshaped, and the lessons have to be read by whoever moves
them or they arrive as boilerplate.

### What is NOT in any phase

**Item 6's enabling, and every `--apply`.** This document proposes; the switches are the
owner's, one at a time. And **item 8 has no "port it everywhere" phase** — D9 asks which
repositories, and the honest answer may be *one more*.

## What this spec deliberately does not do

- **It does not turn anything on.** Enabling protection is an action in the GitHub UI and
  belongs to the owner, not the agent.
- **It does not pick the checks for you.** D5 is per repository on purpose: `shvia-web`'s
  `test` is a 10-minute suite and `repodocs` has none at all — one answer for nine
  repositories would be the same "list written by whoever knew the least" this house keeps
  paying for.
- **It does not implement D3, D8, D9 or D10.** `post-rewrite` versus `pre-push` is a choice between a
  guard that reports and one that refuses, and the fleet has nine copies of whichever wins.

> ⚠️ **One note of method, and it happened inside this document.** The first pass at the
> table in item 6 called every repository "PROTECTED" — the script tested a variable that
> was non-empty because it held the *404 error JSON*. The measurement written to prove
> "empty output is not absence" fell into it on the first run. The table above is the
> second pass.
