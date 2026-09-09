# The stamping chain — eleven items, and the decisions they wait on

> **Status: SPEC. Nothing here is implemented.** It proposes; the owner decides item by
> item, and D1–D7 below are the decisions that unblock them. Written 09/09/2026 after a
> day in which six defects, four false findings and two inert guards all had one shape.

## The shape they share

Every failure this document collects looks the same from inside:

> **The instrument answered something plausible, and nobody checked the trigger.**

The `commit-msg` hook is correct and is never called on `rebase --continue`. `--auto`
is the right flag and waits for nothing when no check is required. A ratchet reads
`max(cru, pt)` and stays green while debt grows underneath. None of them failed loudly.

That is why these are one document rather than eleven tickets: the fix for each is
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

🔬 **And it happened again while this very item was being written**, in `repodocs` itself —
**two sessions writing this same document, in the same checkout.** The evidence is on
`master` and reproduces with one command:

```
$ git log --format='%h %s' origin/master | grep '^[0-9a-f]* 1\.14\.5'
f9609bf 1.14.5 - the release race stops offering three shapes and names the one the evidence chose
544c1b4 1.14.5 - a filtered summary is not a measurement, and four wrong findings in one day say so

$ git log --format='%h %s' origin/master | grep -c '^[0-9a-f]* 1\.14\.4'
1                                      # positive control: a healthy version has exactly one
```

**Two commits on `master` carry the same version number.** Then it repeated one number
higher: the second session's `f0c9ba9 1.14.6 - the stamping chain gets a spec, and branch
protection turns out to be missing in eight of nine` took `1.14.6` while the first was
renumbering into it.

The `pre-push` hook refused both times — *"REJECTED — version 1.14.5 is already on master"*,
then the same for `1.14.6` — and **nothing was forced**. The guard worked. Three things it
did not do, and they are the item:

1. **It refuses at the end.** By the time it speaks, the changelog entry is written, the
   commit is made, and the number is inside both.
2. **The recovery is a renumber by hand** — edit `version.md`, move the changelog block,
   amend the subject. Exactly the gesture item 4 shows is unguarded on `rebase --continue`.
3. **It did not stop the collision that mattered.** `544c1b4` was committed *into the other
   session's working tree*, between that session's edit and its commit, so its changelog
   entry landed in the wrong position and had to be moved. No hook sees that: it is not a
   push, it is two sessions sharing a directory. That is item 10.

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

## D5 — decided 09/09/2026, with the measured cost and the exact names

The owner decided per repository from the measurement below. **The names in the second
column are what GitHub offers as required contexts** — they are *check-run* names, i.e.
job names, not workflow names. 🔬 `CI` is a workflow and **is not selectable**; `assunto`
and `test` are separate check-runs, so requiring one does not drag the other.

| repository | required | measured cost | state on the default branch |
|---|---|---|---|
| `shvia-web` | `assunto` · `test` | 10s · **9m08s** | ✅ green |
| `shvia-desktop` | `Provas (Rust + política do runner)` | ~8m | ✅ green |
| `blue3-intranet` | `Tests (phpunit / MariaDB)` · `Lint (Pint nos alterados + php -l)` · `migrate do zero, sem baseline` | ~3m · 44s | 🔴 **Tests and Lint FAILING** |
| `shvia-code` | `build` | ~4m | 🔴 **FAILING** |
| `repodocs` · `shvia-rota` · `ai-benchmark` · `shvia-site` | **none** | — | no CI exists |

🔴 **Two of them cannot be switched on today.** `blue3-intranet` has been red since
02/09 (three consecutive runs) and `shvia-code` since 03/09 (four). **Requiring a check
that is already failing locks the repository**: no PR merges until someone fixes it. Those
two wait for a green default branch; the switch is not the work, the red is.

⚠️ **The four with "none" are without protection for a reason worth writing down: they
have no CI to require.** Their only workflow is `Release`, which runs **after** the merge —
requiring it would be decoration. They are unprotected by **absence of a check**, not by a
judgement that they carry less risk.

---

## 🔬 The queue's own merge tool went blind, and nobody saw it for 5h49

09/09/2026, and it belongs in this document because it is the spec's thesis arriving in the
instrument the queue uses to **decide a merge**.

A background task was left waiting for a PR's checks with this condition:

```bash
until [ "$(gh pr checks 84 --json state --jq '…')" = "0" ]; do sleep 30; done
```

This `gh` does not accept `--json` on `pr checks`. Every iteration printed a usage error to
stderr, the command substitution returned empty, the comparison was false, and the loop
slept again — **for 5 hours and 49 minutes**, while the PR it was watching had merged hours
earlier. From outside it looked exactly like *waiting*.

> **The tool did not fail. It answered something plausible — an empty string — and the
> caller read it as "still pending".** Same shape as `commit-msg` never being invoked, as
> `--auto` waiting for nothing, as `max(cru, pt)` staying green.

🔴 **Why this one is worse than a wasted process:** the fleet's queue reads
`gh pr checks` to decide whether a merge may happen. That reading is the last gate before
the merge, and it is unpinned — **the day `gh` changes a flag, the gate goes blind in
silence and every answer becomes "not ready" or, with the comparison inverted, "ready".**
D5 does not cover this: a required check protects the merge on GitHub's side, not the
agent's own decision to call it.

**The shape of a fix, not filed as a decision because it needs no owner:** any wait on an
external CLI compares against a value the CLI **actually produced** — a run's `status`, an
explicit `completed` — and treats *empty* as *"did not measure"*, never as a state. It is
the exit-2 rule of `prova-committer-nao-derruba.sh`, applied to a shell loop.

---

## 🔬 D5's measurement, checked by a second session

Re-measured independently on 09/09/2026, from `gh run list --event pull_request` over the
last twelve runs of each repository. The numbers agree with the table above:

| repository | job | measured average | n |
|---|---|---|---|
| `shvia-web` | `test` | **9m06s** | 11 |
| `shvia-web` | `assunto` | 13s | 11 |
| `shvia-desktop` | `Provas (Rust + política do runner)` | 7m58s | 3 |
| `blue3-intranet` | `Tests (phpunit / MariaDB)` | 4m31s | 4 |
| `blue3-intranet` | `migrate do zero, sem baseline` | 41s | 2 |
| `blue3-intranet` | `Lint (Pint nos alterados + php -l)` | 19s | 4 |

⚠️ **And one correction that sharpens the `shvia-code` row rather than contradicting it.**
Its only non-`Release` workflow is `build-windows.yml`, and it triggers on **`push`, not
`pull_request`**. A check-run does appear on a PR whose branch was pushed — so requiring it
works for a same-repository branch — but it never runs against the merge result, and it
would not run at all for a PR from a fork. Requiring `build` there buys less than the row
suggests, and the difference is worth knowing before the switch is thrown.

🔬 Confirmed by the same sweep: `repodocs`, `shvia-rota`, `shvia-site` and `ai-benchmark`
have **no workflow triggered by `pull_request` at all** — the "no CI exists" line is
absence of a trigger, not a repository that happens to have had no PRs.

---

## Why the eight are unprotected: absence from the standard, not a decision

🔬 Measured: `tools/fleet.sh` and `templates/skeleton/` **never mention branch protection**
— the only occurrence of the word in the skeleton is an unrelated security section. And
the single protected repository, `sshvterm-desktop`, is the single one outside
`fleet.sh`'s reach: somebody switched it on by hand there.

> **What the standard does not carry does not arrive.** That sentence is the whole spec in
> one case, and it is why protection becomes an item of the standard here — while the act
> of enabling stays with the owner, because it is a GitHub action and not a repository
> change. No `fleet.sh` mode can do it, and pretending otherwise would put a promise in a
> tool that cannot keep it.

---

### 10. 🔴 The main checkout is used as a working directory, and that is what collided today
`SHVIA-WEB` merged a floor rule into its `AGENTS.md` on 09/09/2026 (`2.110.228`): **the main
checkout is never a working directory; every session opens a worktree.** It is not in
`repodocs`, and `repodocs` is where it was needed hours later.

🔬 **Measured here, today.** Two sessions worked in `~/x/repodocs` at the same time. One
committed `544c1b4` into the other's working tree, **between that session's edit and its
commit** — so a changelog entry written for the top of the file landed below a newer one and
had to be moved by hand. It is the same cause behind four earlier incidents in `SHVIA-WEB`
(`b71d71c`, the duplicated export, the symlinked `vendor`, the dirty `master`), and this is
the first time it landed inside the same directory rather than across two.

**No hook can see it.** `pre-push` guards the push and `commit-msg` guards the subject;
neither is called when a second session writes into the tree you are editing. The window is
between *edit* and *commit*, which is not an event git exposes.

⚠️ **And the rule as merged is honest about being text.** Its registered verification is a
**sample, not a proof** — `git status` on the main checkout answers about the instant, and
two readings the same day disagreed. `SHVIA-WEB` filed the mechanical half as **WT-1**: a
hook that refuses a write in the main checkout while a worktree is alive, exiting non-zero
when it cannot measure. **Waits on: D11.**

---

### 11. 🔴 The stamp tool and the one-subject-per-commit rule contradict each other
🔬 **Measured 09/09/2026 on `shvia-web#94`, and it is a contradiction between two things the
house wrote, not a bug in either.**

`COMMIT-RULE` says a delivery is **split into commits by subject**, and that the changelog
entry travels **in the same commit as the change** — *"é ela que carrega a descrição"*. Four
findings, four subjects, four tests ⇒ four commits, four entries.

`scripts/versao-no-merge.sh` refuses that branch:

```
🔴 há 4 marcadores no CHANGELOG.md — esperado exatamente 1.
   Mais de um significa branch com duas entregas ou rebase mal resolvido.
```

It is not a defensive message it could relax: the script reads the description with
`grep -m1` and stamps **one** version for the branch. **Its model is one entry per branch;
the rule's model is one entry per subject.** Both are written down, and they cannot both be
followed on the same delivery.

**What #94 did, and it was a workaround rather than a decision:** the four entries were
merged into one with four `###` sections, keeping the four commits. It stamped and it
merged. It also means three of the four commits carry no changelog line of their own, which
is the half of the rule that was given up — quietly, by whoever hit the wall, at the moment
of merging. That is the worst place for a convention to be decided.

⚠️ **The reason it is an item and not a note in that entry:** the next person to split a
delivery hits the same wall and picks whichever half they happen to value, and the fleet ends
up with both conventions and no record of the choice. One of the two has to give, in
writing, once.

**Waits on: D12.**

---

## Decisions

| # | Decision | What it unblocks | Cost of saying yes |
|---|---|---|---|
| **D1** | Run `./tools/fleet.sh echo --apply` and `hooks --apply` over the fleet | items 1 and 3 | one pass, 54 repositories, `_quarentena/` excluded by the tool |
| **D2** | Schedule the `version.md` → `CHANGELOG.md` migration | item 2 | 23 repositories, entries reshaped by hand; the automatic version was tried at `1.9.3` and reverted at `1.9.4` |
| **D3** ✅ | **Decided 09/09/2026: `post-rewrite` (D3a).** Reasoning below the table. | item 4 | a guard that REPORTS; the refusal stays with `pre-push`, which already exists |
| **D3a** | `post-rewrite` hook | — | it runs **after** the rewrite: it can report, never refuse. A guard that reports is a different promise |
| **D3b** | Move the check into `pre-push` (which already exists and already compares versions) | — | catches it later, but **refuses** — and `pre-push` is the one gate the fleet already treats as the human's entry point |
| **D4** ✅ | **Decided `1.14.5`: change the instruction, not the code.** `RELEASES-RULE` loses *"running it is always safe"* and gains the measured rule — the workflow covers the push; running the script by hand right after duplicates. Applying it is one template edit + a fleet pass | item 5 | nothing new: it rides the D1 rollout. The two refused alternatives are recorded in the finding so they are not re-opened without new evidence |
| **D5** ◐ | Which checks become required, **per repository** | item 6 | 🔒 **`shvia-web` decided 09/09: BOTH — `assunto` + `test`.** Not the cheap option, and the owner named the reason: *a red `test` merging is today's defect.* The ~10 min per PR is paid on purpose. The other eight stay open — `repodocs` has no test job at all, so one answer for nine was never the shape |
| **D6** ✅ | **Decided 09/09/2026: NO.** Required checks only (D5). Direct push to the default branch stays. | item 6 | none — the fleet's flow is unchanged |
| **D7** | Whether `.continue/` items of this class stay per-repository or centralise here | all nine | centralising makes them visible; it also moves them away from the repository that has to act |
| **D8** | Where the version-carrier guard runs, and whether `fleet.sh` **refuses** to bump a repository with multiple carriers and no synchroniser | item 7 | the refusal is one more case in a script that already refuses several; the cost is a bump that stops working until somebody adds the synchroniser — which is the point |
| **D9** ◐ | **Which** repositories move to stamp-at-merge — not whether. 🔒 **Owner ratified 09/09: NOT the nine.** Which ones remains open, and *"one more"* is a legitimate answer | item 8 | 🔴 *this is the expensive one and the spec does not recommend "all nine".* `versao-no-merge.sh` is ~300 lines serving a repository with 26 PRs in a day; six of the nine would pay that complexity for a collision they never have. Ordered by measured traffic: `SHVIA-WEB` has it, `SHVIA-DESKTOP` is the one with a collision on record, and the rest have none |
| **D10** ✅ | Whether the method lessons become a **fifth echo block** or a document in `docs/` that the agent files point at | item 9 | the block regenerates everywhere and turns method into boilerplate nobody re-reads; the pointer keeps one text and costs a hop. **Not equivalent. 🔒 Owner decided 09/09: the pointer.** The block regenerates everywhere and turns method into boilerplate nobody re-reads |
| **D11** | Whether the *main checkout is never a working directory* rule enters `repodocs` as text, as **WT-1's** mechanical hook, or both | item 10 | the text costs one paragraph in the agent files and is a sample, not a proof; the hook is a fourth file in `tools/git-hooks/` and lands in nine repositories. **They are not alternatives** — the text says what to do, the hook is what makes it true |
| **D12** | Which half gives: **the script accepts N markers** (stamp one version, keep every entry — it already rewrites N subjects, so this is the smaller change) or **the rule accepts one entry per branch** (a delivery keeps its commits, the changelog describes the delivery) | item 11 | 🔴 *not a tie.* The first keeps both halves of `COMMIT-RULE` and costs a loop in one script; the second is free and permanently gives up *"a entrada vem no mesmo commit da mudança"* for any split delivery. The spec leans to the **script**, and says so rather than leaving it open — `shvia-web#94` already paid the second option once, by accident |
* The block regenerates everywhere and turns method into boilerplate nobody re-reads |

### ✅ D3 — decided 09/09/2026: `post-rewrite`

> *"O `pre-push` já mede `version.md` contra o remoto; empilhar carimbo lá acopla duas
> promessas no mesmo hook e pega tarde, com o rebase frio. `post-rewrite` fala na hora, no
> lugar do erro."*

The spec put D3b ahead because it **refuses** where `post-rewrite` only reports. The
decision weighs what the spec left out: **where the person is when the message arrives.**
A refusal at `pre-push` lands minutes or hours after the rebase, with the renumbering cold
and the context to fix it gone; and it makes `pre-push` carry two unrelated promises, so a
failure there stops saying which one broke.

⚠️ **What the fleet accepts, written down so nobody rediscovers it as a defect:**
`post-rewrite` **cannot refuse** — it runs after the rewrite. The gap is closed by the
PAIR, not by the hook alone: the report at the moment of the error, plus the `pre-push`
version comparison that already exists and already refuses.

### ✅ D6 — decided 09/09/2026: no

Required checks only (D5). **Blocking direct push to the default branch is out**, and the
fleet's flow — the agent commits and pushes to the default branch — is unchanged. The
measured problem was a merge with a pending check; D5 alone closes it.

🔴 **D9 is the one to read twice.** Both change how people work rather than what a script does, and both are the kind of decision that looks small in a table and is not.

**D6:** Requiring status checks and blocking direct push are
separate switches. The first makes the merge wait; the second changes how everyone works.
The measured problem — a merge with a pending check — is fixed by the first alone.

---

---

### 🔬 The D5 blocker, answered: the jobs are required one by one

**Yes — `assunto` can be required alone. It does not drag `test`.**

`assunto` and `test` are two jobs in one workflow file (`ci.yml:12` and `ci.yml:176`), and
branch protection does not match on workflows: it matches on **check-run names**. Each job
publishes its own. Measured on `shvia-web`:

```
$ gh api "repos/samirhvbr/shvia-web/commits/<sha>/check-runs" \
    --jq '.check_runs[] | "\(.name)  ::  \(.app.slug)"' | sort -u
assunto  ::  github-actions
release  ::  github-actions
test     ::  github-actions
```

Three names, three independent check runs, from one workflow. *Require status checks to
pass* takes the names — so `assunto` alone, `assunto` + `test`, or any subset, is a valid
answer to D5 per repository.

**Two consequences to weigh, not obstacles:**

- **Requiring only `assunto` lets a red `test` merge.** That is the cheap option: it
  enforces stamping (seconds) without making every PR wait ~10 min. A real trade, not a
  half-measure — and it closes the *measured* problem, which was a merge landing with the
  placeholder still in the subject.
### 🔴 The trap that comes with any required check, and it is not hypothetical here

**A required check that never runs for a given event blocks the merge forever**, waiting for
something that will not come. GitHub does not distinguish *"failed"* from *"never reported"*
— both are simply *not green*.

`assunto` is exactly that shape: `ci.yml:177` gates it on
`if: github.event_name == 'pull_request'`, so it produces **no check run at all** on a direct
push. That is the right shape while protection gates PRs — and it becomes a live trap the
moment somebody pushes straight to the default branch, which is still the flow in eight of
nine repositories (D6 deliberately left it allowed).

**The rule, for whatever goes on the required list:** it has to run on **every event the
protection covers**. Before requiring a job, ask which events it skips — and if it skips one
that can still land on the branch, either widen the job's `if:` or do not require it.

⚠️ This is the same silence as everything else in this document: the check is not wrong, it
is **absent**, and absence reads as *not yet* forever.

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
