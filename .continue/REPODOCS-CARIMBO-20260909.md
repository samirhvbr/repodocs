# The stamping chain — six items, and the decisions they wait on

> **Status: SPEC. Nothing here is implemented.** It proposes; the owner decides item by
> item, and D1–D7 below are the decisions that unblock them. Written 09/09/2026 after a
> day in which six defects, four false findings and two inert guards all had one shape.

## The shape they share

Every failure this document collects looks the same from inside:

> **The instrument answered something plausible, and nobody checked the trigger.**

The `commit-msg` hook is correct and is never called on `rebase --continue`. `--auto`
is the right flag and waits for nothing when no check is required. A ratchet reads
`max(cru, pt)` and stays green while debt grows underneath. None of them failed loudly.

That is why these six are one document rather than six tickets: the fix for each is
mechanical, and the reason they were all open at once is that **the fleet's guards are
content without trigger**.

---

## The six

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
Opened by another session the same day. Same family: the Release side of the stamping
chain has a race the guard does not cover. **Waits on: D4.**

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

## Decisions

| # | Decision | What it unblocks | Cost of saying yes |
|---|---|---|---|
| **D1** | Run `./tools/fleet.sh echo --apply` and `hooks --apply` over the fleet | items 1 and 3 | one pass, 54 repositories, `_quarentena/` excluded by the tool |
| **D2** | Schedule the `version.md` → `CHANGELOG.md` migration | item 2 | 23 repositories, entries reshaped by hand; the automatic version was tried at `1.9.3` and reverted at `1.9.4` |
| **D3** | Which shape closes the `rebase --continue` gap | item 4 | see D3a/D3b below — they are not equivalent |
| **D3a** | `post-rewrite` hook | — | it runs **after** the rewrite: it can report, never refuse. A guard that reports is a different promise |
| **D3b** | Move the check into `pre-push` (which already exists and already compares versions) | — | catches it later, but **refuses** — and `pre-push` is the one gate the fleet already treats as the human's entry point |
| **D4** | Owner of the double-Release race | item 5 | not measured by this session; the other session has the data |
| **D5** | Which checks become required, **per repository** | item 6 | `test` = ~10 min per PR · `assunto` = no merge without stamping · `sshvterm-desktop` already runs three and is the only precedent |
| **D6** | Whether protection also blocks direct push to the default branch | item 6 | it would end "commit and push to master", which is the fleet's current flow in 8 of 9 repositories — this is the expensive half, and the spec does **not** recommend it by default |
| **D7** | Whether `.continue/` items of this class stay per-repository or centralise here | all six | centralising makes them visible; it also moves them away from the repository that has to act |

🔴 **D6 is the one to read twice.** Requiring status checks and blocking direct push are
separate switches. The first makes the merge wait; the second changes how everyone works.
The measured problem — a merge with a pending check — is fixed by the first alone.

---

## What this spec deliberately does not do

- **It does not turn anything on.** Enabling protection is an action in the GitHub UI and
  belongs to the owner, not the agent.
- **It does not pick the checks for you.** D5 is per repository on purpose: `shvia-web`'s
  `test` is a 10-minute suite and `repodocs` has none at all — one answer for nine
  repositories would be the same "list written by whoever knew the least" this house keeps
  paying for.
- **It does not implement D3.** `post-rewrite` versus `pre-push` is a choice between a
  guard that reports and one that refuses, and the fleet has nine copies of whichever wins.

> ⚠️ **One note of method, and it happened inside this document.** The first pass at the
> table in item 6 called every repository "PROTECTED" — the script tested a variable that
> was non-empty because it held the *404 error JSON*. The measurement written to prove
> "empty output is not absence" fell into it on the first run. The table above is the
> second pass.
