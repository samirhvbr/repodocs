# Changelog

Entries in the commit-message format (`version - short description in English`,
see [docs/versioning.md](docs/versioning.md)), newest first. **Each `##` heading is
literally the commit subject** — the entry is written before the commit, so the
sentence that lands in `git log` is one that was weighed rather than improvised
at `git commit` time.

Bodies are narrative: what changed, why, and what was measured. This file is
never rewritten.

## 1.14.16 - the pin rule stops belonging to one repository and becomes the standard's

`1.14.15` moved this repository's release workflow to `actions/checkout@v7` and left it a
tag. BD-03 of the sshvterm review had found the same shape in three fleet repositories and
prescribed fixing it *"na fonte"* — which turns out to be two claims, one true and one not:
the **rule** belongs here; the **file** does not travel from here.

**[ADR-025](docs/decisions.md#adr-025--a-github-action-is-referenced-by-commit-sha-never-by-a-tag)**
— every `uses:` in a fleet workflow names a full 40-character commit SHA, with the readable
tag in a trailing comment. It holds for `actions/*` and third parties alike, because a
first-party exemption is the kind of exception nobody should have to argue in a review. The
reason it is a rule and not a preference: the step in question is the one job this standard
defines that elevates to `contents: write`, and a tag is a pointer its owner can move at any
moment, with no notice on our side.

**The cost is in the ADR rather than left to be discovered.** A pin does not expire; when
the major it points at is retired nothing fails and nothing announces itself. The fleet met
exactly that on 16/09: a workflow pinned to `actions/checkout` v4 ran **green**, with
GitHub's annotation on the successful run saying the Node 20 runtime it declares no longer
exists and had been forced onto 24. So the ADR carries the two consequences that make the
rule survivable — the tag comment is what makes a pin auditable by reading, and a
deprecation annotation on a green run is work rather than noise.

It reaches the fleet as a rule in
[security.md §10](docs/security.md#10-dependency-maintenance), one line of `grep` in
[runbook.md §7](docs/runbook.md#7-verifying-a-repository-still-conforms) where silence is
conformance, and the pin itself in **both** copies of `release.yml` here — this
repository's and the skeleton's. The skeleton was still on `@v5`: a repository created this
week would have been born two majors behind *and* on a tag.

⚠️ **It does not reach the repositories that already exist, and that is measured, not
assumed.** `tools/fleet.sh` writes the two git hooks, `tools/release.sh` and the four echo
blocks, and has never written anything under `.github/workflows/`. The three sshvterm
repositories were fixed in their own commits — `2.1.16`, `1.3.44` and `0.4.32` — before this
one. Any other repository is §8 of the runbook, by hand.

No mechanical guard, for the reason ADR-009 and ADR-024 already give: `pre-push` does not
parse YAML, there is no CI workflow here to host a checker, and the question is one line of
`grep` that a reviewer can run.

## 1.14.15 - the release workflow moves to checkout v7 and its Node 24 runtime

The release workflow moves from `actions/checkout@v5` to `@v7`. Version 7 uses
the Node 24 action runtime, updates its direct and transitive dependencies, and
refuses unsafe fork checkout by default for privileged workflow triggers. This
repository's release workflow runs only on pushes that change `version.md` or
on manual dispatch, so the new fork-checkout restriction does not alter its
trigger or permissions model.

The workflow remains intentionally outside a pull-request CI job: its only
effect is publishing a tag and Release after the version reaches `master`.
Static validation confirms the YAML and action reference are valid, and the
release script's dry run confirms `1.14.15` is the next unpublished version.

## 1.14.14 - a repository whose normative documentation is Portuguese has no row in §8, and EOP has been that shape since 1.76.155

`EOP/CLAUDE.md` carries two rules that contradict each other three hundred lines
apart: its own golden rule 10 (*"pt-BR em docs/ADRs"*) and the `§Language` block
that this repository regenerates into it (*"everything … is written in English
(US)"*). The owner's verdict on 11/09 is that **golden rule 10 wins for EOP** —
`docs/` and the ADRs stay Portuguese, commit messages and the changelog stay
English — which is what the disk has done since `1.76.155`. The practice was never
in doubt; the norm was.

**§8 cannot absorb that today, and the finding is why.** Its three carve-outs key
on *what kind of text* (product strings), *which repository* (the Blue3 internal
ones) and *where in the lifecycle* (`.continue/`, temporary by construction). EOP
is a fourth shape: **one repository, one directory, permanently**, with everything
the English rule exists for — commits, changelog, releases, PRs, issues, code
comments — staying English.

⛔ **Nothing is decided here.** Whether §8 gains a fourth row or EOP's `docs/`
converts is an ADR, and the finding names both shapes with their cost.
`.continue/ACHADO-doc-normativa-em-portugues-20260911.md` carries the measurement.

⚠️ **And the echo was left alone on purpose:** EOP's `§Language` sits inside the
`RELEASES-RULE:repodocs` block, so a fix written there would be undone on the next
regeneration — and, worse, would tell the next reader the contradiction was
resolved. EOP got a note *outside* the block instead, pointing here.

## 1.14.13 - the time-bomb rule enters the spec with the counterexample that keeps it usable

Item 12, with **D13**. Measured in `shvia-web` on 10/09/2026: `master` went red sitting at
the same SHA whose CI had passed **green at 22:35 the night before**, because a test
asserted output from a report whose **branch** depends on `now()`.

`ForensePentest::relogio()` computes `access_expira = CORTE_C188 + 14 days` (`2026-08-26` →
`2026-09-09`). Past that instant the block the test asserted — `SALVAR O LOG É O PASSO 1`,
`tar czf` — **stops existing**, replaced by *"A JANELA DO C188 JÁ EXPIROU"*. Not formatting:
flow. Which is also why asserting only the invariants was not an option — the section under
test lives in one branch, and the file's other 19 cases pass because they assert lines
common to both.

🔴 **It is not flaky, and the distinction is the point.** A flake fails sometimes; this
passed for twelve days and then failed **always**, at an instant the code could compute in
advance. **A flake is re-run; a time bomb is defused.**

The rule, as ratified:

> The danger is not a fixed date in the code — it is a fixed date compared against `now()`
> in a way that makes the output change at a knowable instant. The first is a constant; the
> second is a deadline.

**And the counterexample is what makes it usable**, which is why it is in the spec beside
the rule rather than left in the `shvia-web` changelog.
`LimparContasPentest::DATA_PENTEST` holds **the same date**, in the sibling command, one
line away — and is **not** a bomb, because it compares `$u->created_at` against the constant:
two stored values, no branch turning with the calendar. Without it the rule reads as *"fixed
dates are dangerous"*, and whoever applied it would freeze clocks in tests that never needed
one. A rule that cries wolf is the one somebody switches off.

**D13** asks whether the narrow sweep — `grep -rnE "'20[0-9]{2}-[0-9]{2}-[0-9]{2}'" app/`,
read against the rule — runs across the other eight repositories. The spec leans to
**sweeping and reporting, not fixing in the same pass**: in `shvia-web` 5 of 7 hits were
protocol versions and the 6th was the counterexample, so a hit is a question, not a defect.

## 1.14.12 - D12 goes to the top of the spec as the next implementation, with the sentence that makes it urgent

Ratified, not implemented — this repository has a writer, and the change is theirs to make.
What lands here is the **order**: D12 is the first thing to do on returning, and the banner
at the top of the spec now says so instead of leaving it as one row in a table of twelve.

The sentence that moves it from *next* to *first*:

> While the script refuses N markers, the next split delivery gives up the same half — in
> silence, at the moment of merging.

It is not a prediction. `shvia-web#94` did exactly that on the day the item was written:
four commits by subject, four entries, the script refused, and the entries were merged into
one by whoever hit the wall. **Three of the four commits landed with no changelog line of
their own, and nobody decided that — the tool did.** Every split delivery after it pays the
same price until the script changes.

The machinery is already there, which is why this is the cheap half of D12: the script
rewrites **N subjects** in its stamping rebase. What it does not do is keep N headings.

## 1.14.11 - the stamp tool and one-subject-per-commit contradict each other, and #94 paid it by accident

Item 11, with **D12**. Two things the house wrote, both followed, cannot both be followed on
the same delivery.

`COMMIT-RULE` splits a delivery **by subject** and puts the changelog entry **in the same
commit as the change** — *"é ela que carrega a descrição"*. Four findings, four subjects,
four tests ⇒ four commits, four entries.

`scripts/versao-no-merge.sh` refuses exactly that: *"há 4 marcadores no CHANGELOG.md —
esperado exatamente 1"*. Not a message it could relax — it reads the description with
`grep -m1` and stamps **one** version per branch. Its model is one entry per branch; the
rule's model is one entry per subject.

🔬 **Measured on `shvia-web#94`**, which merged the four entries into one with four `###`
sections and kept the four commits. It stamped and it merged — and three of the four commits
now carry no changelog line of their own. That half of the rule was **given up quietly, by
whoever hit the wall, at the moment of merging**, which is the worst place for a convention
to be decided.

**It is an item and not a note in that entry** because the next person to split a delivery
hits the same wall and picks whichever half they happen to value, and the fleet ends up with
both conventions and no record of the choice.

**D12 is not a tie, and the spec says which way it leans:** the script accepting N markers
keeps both halves of the rule and costs a loop in one script — it already rewrites N subjects,
so the machinery is there. The rule accepting one entry per branch is free and permanently
gives up *"a entrada vem no mesmo commit da mudança"* for every split delivery. `#94` already
paid that price once, by accident.

## 1.14.10 - `shvia-web` requires both checks, and the trap of the check that never runs gets its own section

**D5 ◐ — `shvia-web` decided 09/09: both `assunto` and `test` are required.** Not the cheap
option, and the owner named the reason rather than the cost: *a red `test` merging is today's
defect*. The ~10 minutes per PR is paid on purpose. The other eight repositories stay open —
`repodocs` has no `test` job at all, so one answer for nine was never the shape.

**The trap is promoted from a bullet to a section**, because it stops being hypothetical the
moment a check is required. GitHub does not distinguish *"failed"* from *"never reported"* —
both are simply not green, so **a required check that never runs for a given event blocks the
merge forever**.

`assunto` is exactly that shape: `ci.yml:177` gates it on `github.event_name ==
'pull_request'`, so it produces **no check run at all** on a direct push. Correct while
protection gates PRs, and a live trap the moment somebody pushes straight to the default
branch — which D6 deliberately left allowed, in eight of nine repositories.

The rule that comes out of it: whatever goes on the required list has to run on **every event
the protection covers**. Before requiring a job, ask which events it skips; if it skips one
that can still land on the branch, widen the job's `if:` or do not require it.

It is the same silence as the rest of this document. The check is not wrong — it is
**absent**, and absence reads as *not yet*, forever.

## 1.14.9 - the D5 blocker is answered, item 8 becomes reproducible, and the collision gets an item of its own

Three things the owner asked for, none of them implemented.

**D5 is unblocked, and the answer is measured, not inferred.** `assunto` and `test` are two
jobs in one workflow (`ci.yml:12` and `ci.yml:176`), and branch protection does not match on
workflows — it matches on **check-run names**, one per job. `gh api .../check-runs` on
`shvia-web` returns three: `assunto`, `test`, `release`. So **`assunto` can be required
alone and does not drag `test`**, and D5 can be answered per repository with any subset.

Two consequences are written beside it rather than left to be discovered: requiring only
`assunto` lets a red `test` merge — the cheap option, and it does close the measured problem
— and `assunto` runs only on `pull_request`, which is the right shape here but carries the
general trap that **a required check that never runs for an event blocks the merge forever**.

**Item 8 now reproduces from `master` with one command.** It said "two sessions stamped
1.14.5, then 1.14.6"; it now carries the hashes, both subjects, and a positive control:

```
$ git log --format='%h %s' origin/master | grep '^[0-9a-f]* 1\.14\.5'
f9609bf 1.14.5 - the release race stops offering three shapes and names the one the evidence chose
544c1b4 1.14.5 - a filtered summary is not a measurement, and four wrong findings in one day say so
```

Two commits on `master` with the same version number. The control (`1.14.4`) returns one.
The item also names the three things `pre-push` did **not** do, and the third is why item 10
exists: `544c1b4` was committed *into the other session's working tree*, between that
session's edit and its commit, so a changelog entry written for the top of the file landed
below a newer one. No hook sees that — it is not a push, it is two sessions sharing a
directory.

**Item 10: the main checkout is used as a working directory.** `SHVIA-WEB` merged the floor
rule at `2.110.228` — *the main checkout is never a working directory; every session opens a
worktree* — and it is not in `repodocs`, which is where it was needed hours later. It is the
same cause as four earlier incidents there, and the first to land inside one directory
rather than across two. **D11** asks whether it enters as text, as the `WT-1` hook, or both,
and says they are not alternatives: the text says what to do, the hook is what makes it true.

**Owner ratifications recorded:** D9 ◐ — **not the nine**; which ones stays open and *"one
more"* is a legitimate answer. D10 ✅ — **the pointer**, not a fifth echo block.

## 1.14.8 - D3 and D6 are decided, and the queue's own merge tool is caught reading silence as a state

**D3 — `post-rewrite`.** The spec ranked `pre-push` higher because it refuses where
`post-rewrite` only reports. The owner weighed what the spec had left out: **where the
person is when the message arrives.** A refusal at `pre-push` lands with the rebase cold
and the context gone, and it makes one hook carry two unrelated promises — so a failure
there stops saying which one broke. The gap is closed by the pair: the report at the
moment of the rewrite, plus the version comparison `pre-push` already refuses on.

**D6 — no.** Required checks only. Blocking direct push to the default branch is out, and
the fleet's flow is unchanged. The measured problem was a merge with a pending check, and
D5 alone closes it.

### 🔬 The finding that earned its own section

A background task waited **5 hours and 49 minutes** on a PR that had merged hours before.
Its condition called `gh pr checks --json`, which this `gh` does not accept: every
iteration printed a usage error, the substitution returned empty, the comparison was
false, and it slept again. From outside it was indistinguishable from waiting.

It belongs in this spec because it is the spec's own thesis arriving in **the instrument
the queue uses to decide a merge**. That reading is the last gate before the merge and it
is unpinned: the day `gh` changes a flag, the gate goes blind in silence. D5 does not
cover it — a required check protects the merge on GitHub's side, not the agent's decision
to call it. The shape of the fix is the exit-2 rule applied to a shell loop: compare
against a value the CLI actually produced, and treat *empty* as *"did not measure"*.

### D5's numbers, checked by a second session

Re-measured independently and they agree — `test` at 9m06s over 11 runs, `assunto` at 13s,
`Provas` at 7m58s, and `blue3-intranet`'s three between 19s and 4m31s.

⚠️ **One correction that sharpens the `shvia-code` row instead of contradicting it:** its
only non-`Release` workflow triggers on **`push`, not `pull_request`**. The check-run does
appear on a pushed branch, so requiring it works for a same-repository PR — but it never
runs against the merge result and would not run at all from a fork. Requiring it buys less
than the row suggests.

## 1.14.7 - D5 is decided, and two repositories cannot switch protection on because their checks are already red

The stamping spec gains the measurement that made D5 decidable, and one finding that
changes the order of the work.

🔬 **The required contexts are job names, not workflow names.** `CI` is a workflow and
GitHub does not offer it; `assunto` and `test` are separate check-runs, so requiring the
10-second subject gate does **not** drag the 9-minute suite along. That was the open
question, and it is answered: the two are independent.

🔴 **`blue3-intranet` and `shvia-code` cannot be switched on today.** Their checks have
been failing on the default branch since 02/09 and 03/09 respectively — three and four
consecutive runs. **Requiring an already-red check locks the repository**: nothing merges
until it is fixed. The switch is not the work there; the red is.

The four without CI stay without protection, and the reason is recorded so it does not
read as a risk judgement later: their only workflow is `Release`, which runs **after** the
merge. Requiring it would be decoration.

**And the tese closes.** `fleet.sh` and `templates/skeleton/` never mention branch
protection; the single protected repository is the single one outside `fleet.sh`'s reach,
switched on by hand. The eight are open by **absence from the standard**, not by decision
— *what the standard does not carry does not arrive*. Protection becomes an item of the
standard; enabling stays with the owner, because no `fleet.sh` mode can perform a GitHub
action and putting that promise in the tool would be a promise it cannot keep.

## 1.14.6 - the release race stops offering three shapes and names the one the evidence chose

> **Renumbered from `1.14.5` before pushing.** Another session had already stamped that
> number on `master` while this entry was being written — in the same checkout, which is
> the floor rule of the fleet being broken in `repodocs` itself. **The `pre-push` hook
> caught it** (*"version 1.14.5 is already on master"*) and refused; nothing was forced.
> That refusal is the guard working, and it is the same collision family this repository
> is about to write a spec for.

The finding from `1.14.3` ended with *"a lead, not a decision"* and three candidate fixes.
Two controls later there is no reason to keep offering three: `1.14.3` and `1.14.4` were
pushed **without** the manual run and each got exactly **one** Release, while `1.14.2` —
the one where the script was run right after the push — has two on the same tag.

**The decision: change the instruction, not the code.** The workflow publishes correctly on
its own, so nothing in `release.sh` is broken and nothing in it needs a lock. What is broken
is a sentence telling the operator to start a second publisher inside the same seconds.

The two alternatives are recorded as refused, so nobody re-opens them without new evidence:
re-checking after creating is code in nine repositories for a race that stops existing when
the sentence changes, and it narrows the window without closing it; retiring the manual path
is the right destination in the wrong order, because that path exists precisely while the
workflow is not yet everywhere (`fleet.sh check` still reports `9× release.sh differs` and
`9× hooks not enabled`).

The sentence that goes is **"Running it is always safe, so it is both the check and the
fix"** — false in exactly the situation the surrounding text puts the reader in. The
replacement is written out in the finding, and says what was measured rather than what was
assumed: the workflow covers the push; running the script by hand right after duplicates.

**Not applied.** It is one edit in `templates/echo-blocks/RELEASES-RULE.md` followed by a
fleet rollout, and rollouts are sequenced in the spec rather than done in passing.

## 1.14.7 - the stamping spec gains the three items about who assigns the number, and the phases

`1.14.6` wrote the spec with six items and D1–D7. Three of the day's failures were not in
it, and they share a subject none of the six touches: **who assigns a version number, and
when**. They are added as items 7–9 with D8–D10, and the document gains the phase order it
did not have. Nothing above item 7 was changed except **D4**, which said the measurement
lived with another session — it now says what that measurement showed.

- **Item 7 — the version-carrier guard runs after the commit** (M1 of the 08/09 review,
  unresolved). `build.rs`, `sync-version.mjs` and `sync-version.sh` all exist and all work,
  in CI, after the push. Measured result: three red `master` in one day from the same
  gesture. Same sentence as items 4 and 5 with a different subject: **the guard is correct
  and the trigger is late.**
- **Item 8 — one repository stamps at merge and the other seven do not.** Measured:
  `scripts/versao-no-merge.sh` exists in `SHVIA-WEB` and nowhere else. `SHVIA-WEB` moved
  there on 29/08 after four collisions in one day between four sessions; `SHVIA-DESKTOP`
  still stamps in the branch and produced the `1.4.31` collision that led to item 4.
  🔬 **It happened again while the item was being written, here**: two sessions stamped
  `1.14.5`, then `1.14.6`. The `pre-push` hook refused both times and nothing was forced —
  the guard worked, and it refuses at the end, after the entry is written.
  🔴 The spec does **not** recommend porting the script to nine repositories: D9 asks
  *which*, and the honest answer may be one more.
- **Item 9 — the method lessons live in one repository.** The premise this started from was
  wrong and the correction is the item: `fleet.sh echo` **cannot** overwrite them
  (`stamp_block()` replaces only between markers; every method section sits above them).
  The real risk is **non-arrival**, and it does not close by itself.

**The phases are the part the six-item version was missing**, and the order is not
preference. Phase 0 closes D8 and D3 **before** any fleet pass, because a rollout bumps a
version in every repository it touches — with item 7 open, the rollout *is* the gesture
that produced the three red `master`. Phase 1 is the pass, and the D4 edit has to land in
the template **before** it, or the false sentence gets stamped into nine repositories on
purpose.

Still a spec. Nothing implemented, no switch turned on.

## 1.14.6 - the stamping chain gets a spec, and branch protection turns out to be missing in eight of nine

Six items in one document because they share a shape, not a subject: **the instrument
answered something plausible and nobody checked the trigger.** The `commit-msg` hook is
correct and never runs on `rebase --continue`; `--auto` is the right flag and waits for
nothing when nothing is required; a ratchet reads `max(cru, pt)` and stays green while
debt grows under it. None failed loudly.

🔬 **The new measurement: 8 of 9 repositories have no branch protection.** Only
`sshvterm-desktop` has any (`tests,servidor,build`). That is what makes `gh pr merge
--auto` inert — it waits for **required** checks, and there are none — proven live on
`shvia-desktop#3`, which merged instantly reporting `auto=false`. Until that changes,
every defence against a blind merge is human discipline, and that discipline failed the
same day it was written down, with the person who wrote it.

The spec proposes and does not implement. D1–D7 are the decisions each item waits on, and
two deserve reading twice: **D3**, because `post-rewrite` runs after the rewrite and can
only report while `pre-push` can refuse — different promises, nine copies of whichever
wins; and **D6**, because requiring checks and blocking direct push are separate switches,
and only the first fixes the measured problem. Blocking direct push would end the
commit-and-push flow that 8 of 9 repositories use today, and the spec does not recommend
it by default.

⚠️ Recorded inside the document: the first pass at its own protection table called every
repository "PROTECTED", because the script tested a variable that was non-empty for
holding the 404 error JSON. The measurement written to prove *"empty output is not
absence"* fell into it on the first run.

## 1.14.5 - a filtered summary is not a measurement, and four wrong findings in one day say so

Sixth entry in §6 of `conventions.md`, and the one with the highest count behind it.

Four false or inverted findings on 09/09/2026, all from believing a summariser instead of
the raw exchange: `/tmp` read as "outside the sandbox" **twice**, in two different
instruments, when `workspace-write` includes it by design; a `sandboxMode` field that does
not exist being sent and silently discarded, so a day of measurements described the
server's default rather than the setting under test; and a `tool_call` reported missing
that had been emitted all along, hidden by a summariser printing two event types and a
`grep` that died of pattern complexity and returned empty.

**Empty output is not absence, and partial output is not the whole.** None of the four
failed loudly — each instrument answered something plausible, which is what made the wrong
reading easy. What broke the error every time was the same move: dump the unfiltered
exchange and read it.

## 1.14.4 - the release race control came back with a number, and the finding stops being conditional

`1.14.3` was pushed without running `tools/release.sh` by hand. The tag ended with
**exactly one Release**, published by the workflow alone — so the workflow covers the normal
path on its own, and the duplicate measured on `1.14.2` came from the second publisher
rather than from the workflow misbehaving.

The finding was written before the result existed and said *"if the tag ends with one
Release…"*. It now carries the number. That matters beyond tidiness: a conditional in a
record is an invitation for the next reader to assume the outcome, and assuming an outcome
that was never measured is the failure this week has been spent naming.

With evidence behind it, the cheapest of the three shapes is also the supported one:
**change the instruction, not the code** — `RELEASES-RULE` telling the operator to push and
let the workflow publish, running the script by hand only when the workflow is absent or has
failed. The *"running it is always safe"* sentence goes either way.

## 1.14.3 - the finding that one tag can carry two Releases, and the control that proves the normal path

Registered, not fixed — `tools/release.sh` and `release.yml` ship to the whole fleet.

Measured while verifying the `1.14.2` release, and **produced by following the documented
instruction**: the `RELEASES-RULE` block says to run `./tools/release.sh` after pushing, and
`release.yml` fires on every push and calls the same script. Both decide by asking whether
the Release already exists, and in a race both ask before either answers. The GitHub API
does not refuse a second Release on an existing tag, so `1.14.2` ended with **two ids on one
tag, created in the same second**. Every version before it has exactly one.

The sentence that has to change is in the echo block in every repository of the fleet:
*"running it is always safe, so it is both the check and the fix"*. Idempotent alone it is;
concurrency-safe it is not — and "always safe" is what made running it right after a push
look like diligence. It is the week's shape one level up: an instrument reporting a property
it does not have **under a condition nobody tested**. `release.sh` was tested alone, never
beside itself.

**The control, run on this very version:** `1.14.3` was pushed and the script was **not**
run by hand. If the tag ends with one Release, the workflow alone covers the normal path and
the manual run is only ever a repair — which is the cheapest of the three fixes the document
names, because it changes no code, only the instruction.

The duplicate on `1.14.2` was deliberately **not** deleted: removing a published Release is
outward-facing and is the owner's call. `Latest` already sits on `385845772`, so the
one-line cleanup changes nothing visible.

Full record: [`.continue/ACHADO-duas-releases-mesma-tag-20260909.md`](.continue/ACHADO-duas-releases-mesma-tag-20260909.md).

## 1.14.2 - the finding that a search returning zero is being read as a conclusion

Registered, not fixed. It is a rule about method, it applies to all nine repositories,
and its home is the template — which is why it is here and not in the repository that
tripped over it.

Found in `SHVIA-WEB`, doing a sweep that a real defect had made necessary: a cleanup
listener hooked on `deleted` for a model that soft-deletes, so trashing a project
destroyed its scope and **restoring it silently widened** the project's reach. The
obvious follow-up was *which other models with `SoftDeletes` have the same problem*, and
the first step of answering it was `grep -c 'use SoftDeletes;'`.

It answered **0** for three models that all soft-delete. They write it as
`use HasFactory, SoftDeletes;`. Three of the five rows of a table whose entire purpose
was to say where the defect could repeat were about to be reported as not applicable.

**`0 occurrences` is a plausible answer and is indistinguishable from `does not exist`.**
The pattern did not error and did not warn: it returned the same number a correct search
returns in a healthy repository. It is the fourth shape of a silence this standard already
names — a test that skips and reads as passing, an incomplete allowlist that is green, a
review panel that agrees on one inherited premise — and the worst of the four, because
the output of a correct search and a broken one are byte-identical. A search that returns
too much gets noticed; one that returns too little gets believed.

The lesson, and it is the usable form because it does not require suspecting the pattern:

> A search that returns zero requires a positive control before it becomes a conclusion:
> look for something you KNOW exists, using the same pattern. If the control also returns
> zero, the pattern is wrong — not the repository.

It was applied to this document while writing it. A term the owner referred to, `D-NOVA`,
did not appear anywhere; the zero was not trusted until the same search, over the same
paths, found `GH-F2` where it was known to be. The control passed, so the zero is real:
**`D-NOVA` is not written down anywhere in the fleet.**

**An adjacent premise was measured and corrected.** The note that brought this in said
three fleet-wide lessons in `SHVIA-WEB/AGENTS.md` risk being overwritten by the next
`fleet.sh echo`. It cannot: `stamp_block()` replaces only what lies between the
`<!-- NAME:repodocs -->` markers, and in that file (1482 lines) the markers are at
1342–1402 and 1438–1482 while every method section is above 1342. The instinct was right
and the mechanism was not — the real risk is **non-arrival**, not overwriting: a lesson
about method living in one repository is a lesson the other eight do not have, and
nothing carries it there.

Full record, including the provenance of the owner's count of six (two measured here,
four not verified — §16) and the two shapes a guard could take:
[`.continue/ACHADO-busca-que-devolve-zero-20260909.md`](.continue/ACHADO-busca-que-devolve-zero-20260909.md).

## 1.14.1 - the finding that `commit-msg` never runs on `rebase --continue`

Registered, not fixed. The hook is the same template in nine repositories and the change
lands in all of them, so it needs a spec rather than a patch made in passing.

Found while renumbering a version collision in `SHVIA-DESKTOP`: a commit landed with its
subject saying `1.4.33` while `version.md` said `1.4.34`, and the guard that exists to
catch exactly that said nothing. It was caught by re-reading `git log`.

Measured in a throwaway repository carrying the fleet's own `commit-msg`, with one log
line inserted **before every early exit** — that line is what separates *"git never called
it"* from *"the hook ran and returned"*, and the two have different fixes. Positive
control checked first.

`commit`, `commit --amend`, `cherry-pick --continue` and `rebase -i` (reword) all invoke
the hook and all refuse a mismatched subject. **`rebase --continue` never calls it**, and
the mismatched commit lands. The gap is that narrow: `rebase -i` with `reword` is fine, so
it is the `--continue` step, not rebase as a whole.

🔴 **`merge --continue` is NOT the bug.** The hook is called and exits at `commit-msg:29`
on `MERGE_HEAD`, with the reason written at line 23: a merge's versions live in the
commits being merged. It is a declared exemption, and it is the row most likely to be
"fixed" by mistake.

The lead, measured and left open: `post-rewrite` does not exist in `tools/git-hooks/`
today, and git calls it after rebase and amend with the list of rewritten commits. But it
runs **after** the rewrite — it can report, not refuse — and a guard that reports is not
the promise a guard that blocks makes. The spec has to choose, out loud.

Full table, method and consequence:
[`.continue/ACHADO-commit-msg-no-rebase-20260909.md`](.continue/ACHADO-commit-msg-no-rebase-20260909.md).

## 1.14.0 - the ADR count in the docs index and the agent files stopped at 019 and 018

`docs/README.md` announced *"ADRs 001–019"* and both agent files announced
*"ADRs 001–018"*, while `decisions.md` runs to 024. The index of a record is
part of the record: a reader who trusts either number stops looking five
decisions early, and the five it hides are the language carve-outs, the queue
rule, the fork rule and the one this version adds.

Three numbers, one truth, and the two that were wrong were wrong by different
amounts — which is what a count maintained by hand does. It is the same failure
`1.10.3` recorded in the queue's own review header, in the file whose §4 says a
document made stale by a change is fixed in the same pass.

## 1.14.0 - the closing checklist asks whether the tests ran, and the skeleton asks how they run

A rule that lives only in `conventions.md` is a rule an agent meets after the
delivery is already written. This is the half that arrives before it: one line in
the checklist that closes a version, and one line in the skeleton that a new
repository has to fill in.

The checklist line sits next to the one about a document made stale in the same
pass, and it asks the same shape of question — did the thing that keeps this
honest travel with the change? It offers the exception in the same breath, so
the honest answer is never silence: *or the changelog entry says why not and what
was checked instead.*

The skeleton gains **`Tests run with:`** directly under `Runs locally with:`,
because a new repository was being asked how it runs and never how it is
validated, and clause 4 needs a command anyone can repeat. `docs/repodocs.md` §7
— the page that tells a new repository where each question is answered — gains
the row for *"does this change need a test, and did it run?"*.

The runbook says the part that is easy to get wrong in a repository whose
permissions are deliberately narrow: **the command goes on the line before the
permission exists.** Running a suite needs the command granted in
`.claude/settings.json`, and that grant is the owner's act. Until it is made, the
agent writes what it could not run and what it checked instead — the exception
of clause 5, used as designed rather than as a way out.

## 1.14.0 - a change in behavior ships with the test that fails when the behavior breaks

Nothing in this norm said that a feature is born with a test. The word *test*
runs through the whole repository and never once means that: `pre-push` runs no
suite and explains why, [ADR-009](docs/decisions.md) and ADR-013 keep a
build-and-test workflow out of this repository, and `versioning.md` uses "test"
for the question a commit subject has to survive. The skeleton's `CLAUDE.md`
asked a new repository how it **runs** and never how it is **validated**.

The hard part of writing the rule is the line between behavior and
implementation, and everything else follows from getting it right. A feature
refuses to open a ticket with no category; the test asserts the refusal.
Tomorrow someone swaps the form component, rewrites the validation or makes it
faster, and the test still passes — because a ticket with no category is still
refused. The day one gets through, it fails. A test that instead breaks whenever
the code moves is a tax on every refactor, and it gets deleted within a year by
someone who is not wrong to delete it.

[§9 of conventions.md](docs/conventions.md) carries five clauses, each
normative. New and changed behavior ship with tests proportional to the risk,
and extending an existing test is often enough. A bug fix ships with the test
that reproduces the defect, red before and green after, whenever that is
feasible. **A failing test is never edited to make it green** — first decide
whether it is a regression or an intentional change of requirement, and only the
second justifies moving the expectation; that clause is written for agents above
all, because turning red into green is the shortest path to a delivery and the
one path that removes the tripwire. The delivery includes actually **running**
the pertinent tests, by a command anyone can repeat, which is why the skeleton
now asks each repository to fill in a *Tests run with* line. And exceptions are
proportional and written down in the changelog entry, in a sentence — which is
what keeps the rule from becoming bureaucracy on one side and a silent waiver on
the other.

**It was adopted with no incident behind it, and that is deliberate.** Most
decisions in `decisions.md` open with something measured: four `version.md`
collisions in one day, 26 placeholder subjects on a master, eight renumbered
changelog entries. This one opens with the reasoning. A concrete case would make
the record stronger, and it is not a condition for deciding when the problem and
the benefit can both be stated honestly.

Two consequences land on this repository itself. `tools/fleet.sh` and
`tools/release.sh` are under the rule from this version on, and the
four-repository fixture that the `1.11.x` entries call *"how this script is
tested"* is not in the repository at all — it lives in a scratch directory, and
bringing it here is the first thing clause 4 asks. And
[ADR-009](docs/decisions.md), which keeps CI out of a documentation repository,
stays in force with its premise now dated: *"there is no suite to run"* becomes
false the day `tools/` has one, and it is revisited **that day, explicitly**,
never in silence.

There is no mechanical guard, by the same reasoning as the queue rule: this puts
a question to a reader, because the hook that could ask it would be the
four-minute hook `pre-push` was designed not to be.

**This delivery is documentation, so no automated test applies** — clause 5's
exception, stated here as the clause requires. What was checked instead: both
pairs of twins still match below the H1; `grep` confirmed that nothing links the
`#9-where-this-convention-applies` anchor before renumbering it to §10, and that
`#8-language` is stamped across the fleet and was therefore left alone; and the
`commit-msg` hook verified the subject against `version.md` on each of the three
commits.

## 1.13.0 - a fork we own has a version of its own, and fifteen of them were outside every measurement

Fifteen repositories of this fleet are forks of somebody else's project that we
own and modify. **Two version themselves. Thirteen do not**, and cannot answer
the question that matters the moment a fork breaks: which upstream point is
this, and how far past it are we?

The two that do invented the same shape independently, which is why this ADR
follows them rather than replacing them:

| Repository | `version.md` | Why that shape |
|---|---|---|
| `SHVIA/strix` | `1.6.2+shvia.15` | PEP 440 local version — `pip` shows it |
| `pve-manager` | `9.2.10+blue3.1` | Debian package version — the `.deb` carries it |

Both reasoned correctly about the hard part: **the `X.Y.Z` belongs to the
upstream and must not be edited**, because that field lives in their
`pyproject.toml` or their changelog, and editing it conflicts on every sync.

And both put the defect in the same place. `1.6.2` and `9.2.10` are the **first
semver** of those files, and the first semver is what everything here reads
([ADR-012](docs/decisions.md)) — the hooks, `release.sh`, `fleet.sh`. Our tooling
was reading a number **we do not control, cannot bump, and that moves on somebody
else's schedule**, including backwards relative to us when an upstream reverts.
`release.sh` in `strix` would have tagged `1.6.2`: a name that belongs to their
release, not to ours.

[ADR-023](docs/decisions.md) gives a fork its own `X.Y.Z` as the **first** semver,
starting at `0.1.0` when our changes start; a declared **Upstream** line naming
the project and the ref; and a package string **derived** from the two —
`1.6.2+shvia.0.15.0` — which is a product identifier consumed by `pip` or `dpkg`,
the same category as UI text, and never the first semver in the file. A sync is a
delivery: it changes what the fork is, so it bumps and its entry names the point
we moved to. An `upstream` remote becomes mandatory — four of the fifteen have
none, which means nothing in them records where they came from.

**The second half of this is that `check` could not see them at all.** The
heuristic that decides whether to *write* to a repository — are the last five
subjects ours? — was also deciding whether to *read* it. Fifteen repositories we
own sat outside every measurement this standard makes, and the report said "54
repositories" as though that were all of them. `check` now has a `FORKS WE OWN`
section that names what each is missing, and the summary line counts both.

**A fork graduates by itself.** Once it adopts our subjects the same heuristic
stops classifying it as upstream-shaped, and it starts receiving the hooks and
the echo blocks like any other repository. The test is the adoption, not a list
somebody has to maintain.

Nothing about what we write **into** an upstream changes: a pull request there
follows their language and their commit shape ([ADR-019](docs/decisions.md)).

## 1.12.2 - a changelog is recognised by what it is, not by the word "changelog" in its title

The pass decides whether a repository already has a changelog before it creates
one, and it decided by grepping `version.md` for the word *"changelog"*. That is
a test of a title, not of a file. `KIDS/KIDS-PAVIO` keeps its whole record in a
`version.md` headed **`# Versões`**, so the word was absent, the pass concluded
there was no changelog anywhere, and it created a second one beside the real one.

That is the same duplicate `1.9.4` was written to prevent — and it slipped
through the fix, because `1.9.4` fixed the *decision* (do not create a second
changelog) and left the *detection* naïve. A guard is only as good as the thing
it measures.

The test is now what a changelog is made of: a heading that is a version, or one
whose words are *changelog* or *versões*. Checked against the fleet: the 13
repositories with no changelog anywhere still read as empty, and the ones that
keep theirs inside `version.md` are recognised, `KIDS-PAVIO` included.

Two other defects in the same repository are what made this visible, and both are
fixed upstream: the bump that renumbered an entry instead of adding one
(`1.12.1`), and this. `KIDS/KIDS-PAVIO` is repaired at its own `0.4.9` — the top
entry is back to the version it describes, the eight renumbered deliveries are
reconstructed from their commit subjects and diffs and marked as reconstructed,
the duplicate file is gone, and `version.md` now declares its version on a line
of its own so the first semver is a declaration rather than an entry.

**Its repair was refused once by the hook this standard installed**, which is
worth recording. `git add version.md CHANGELOG.md` failed as a whole because
`CHANGELOG.md` had already been removed by `git rm`, so nothing was staged, the
index still held the old version, and `commit-msg` refused: *"subject says
0.4.9, version.md says 0.4.8"*. The guard caught a real mistake in the act of
repairing an older one.

## 1.12.1 - a bump that rewrites the first semver renumbers a changelog entry when that is what the first semver is

The bump in `fleet.sh` replaces the first semver in `version.md`. That is the
first-semver rule of [ADR-012](docs/decisions.md) applied to *writing*, and it is
correct for both shapes the fleet actually has — a bare `0.1.9`, and a markdown
file declaring `**Versão atual:** \`0.1.9\`` on line 3. Twenty-seven of the
twenty-eight markdown files look like the second.

The twenty-eighth is `KIDS/KIDS-PAVIO`, whose `version.md` **is** its changelog
and declares no current version at all. Its first semver is the heading of the
top entry:

```markdown
# Versões

Formato: `X.Y.Z - descrição`. A mesma linha vira a mensagem do commit.

## 0.4.8 - três níveis de dificuldade e refino visual
```

So every bump there has renamed an entry that already happened instead of adding
one. **Eight consecutive sweeps did it** — `Releases automaticas` on 02/09, three
`COMMIT-RULE` regenerations, `the human gate`, and both of this session's fleet
passes — walking one entry from `## 0.4.0` to `## 0.4.8`, keeping the words
*"três níveis de dificuldade e refino visual"* attached to whatever number was
current. That repository now has a single changelog entry, describing work from
`0.4.0`, labelled `0.4.8`, and no record whatsoever of the eight deliveries in
between. `git log` has them; the changelog does not.

**This is older than the tool that inherited it**, which is the part worth being
precise about: three of the eight predate `fleet.sh` entirely. The pattern was a
hand-written sweep doing exactly what the script later automated, and automating
it made it faster rather than newer.

`fleet.sh` now refuses. Before bumping it reads the line the first semver sits
on, and a line starting with `#` is a heading — an entry, not a declaration. The
repository is skipped with that sentence, and `check` reports it as a finding of
its own: *"version.md declares no current version"*. Refusing is the right output
because the fix is a decision about that repository's changelog, not something a
fleet pass gets to make at fifty repositories a minute.

The general shape, for the next file that looks unusual: **the first-semver rule
says where to *read* the version. It does not say that position is safe to
*write*.** Reading a number and writing over it are different acts, and this
standard had one rule doing both jobs.

## 1.12.0 - an override moves when the version is decided, never whether every commit carries it

[ADR-017](docs/decisions.md) let one repository stamp its version at merge instead
of in the commit, for a measured reason: four `version.md` collisions in a single
day between four parallel sessions. What it never said is that the late stamp has
to reach **every** commit of the delivery. SHVIA-WEB's implementation did not:

```bash
TOPO="$(git log -1 --format=%s)"     # one commit
case "$TOPO" in
    '(versão no merge)'*) git commit -q --amend -m "$NOVA - $DESC" ;;
esac
```

`git log -1` is `HEAD`. And [ADR-016](docs/decisions.md) makes several the normal
case — **splitting a delivery into blocks is the default**, and the blocks share
one version. Every block but the last went into `master` carrying the literal
placeholder `(versão no merge)` in its subject. **Measured on 08/09/2026: 26 of
them**, the most recent from the previous day, and `master` is not rewritten, so
they are permanent. `dece273` and `88a7769` are a pair from the same Painel
delivery; the siblings that became their own pull requests came out correctly
stamped, which is what made the pattern legible at all.

**Neither ADR was wrong, and that is the finding.** ADR-016 says split by
default. ADR-017 says the version may be decided later. Nobody wrote down what
their product requires, and the gap sat in the one place a fleet norm is hardest
to see: inside the single repository that is allowed to be different.

The guard that repository already had is worth naming, because it is why this
went unseen for nine days. It counts markers in `CHANGELOG.md` and refuses
anything but exactly one — correct, since a delivery has one entry. It measures
the changelog. Nobody was counting subjects.

**ADR-017 gains a second half**, and it is normative for any repository that ever
takes the override: stamp every commit of the delivery, each keeping its own
description; **refuse rather than guess** when the branch cannot be swept — a
merge commit in the range would be flattened, and flattening someone's merge to
fix a subject is not a trade this norm makes; and **guard before the merge, then
again in CI**, because the 26 did not arrive from the stamp failing — they
arrived from it not being run. Rewriting those subjects is legitimate: they are
branch commits that have never been published. A branch already pushed needs a
`--force-with-lease` **on that branch**, never on the default one.

**A placeholder in a subject on the default branch is a defect, always.** The
version exists so that `git log` alone answers *what happened, when, why, and at
which version*; a subject reading *"(versão no merge)"* answers the last one with
a promise.

The rule reaches the fleet in the `COMMIT-RULE` block, which is where an agent
meets the override clause, and in
[versioning.md](docs/versioning.md#the-bump-clause-is-the-one-a-repository-may-override-in-writing).
SHVIA-WEB is fixed at its own `2.110.194`: the stamp sweeps
`merge-base..HEAD` through a `git rebase --exec`, refuses a branch with a merge
commit, refuses to finish while any placeholder remains, and a new `assunto` job
fails a pull request whose commits still carry one. Its 26 are recorded there and
left alone — history is not rewritten.

## 1.11.1 - the pass survives a repository that fails, and says which one and why

Both passes died in the middle. `echo` stopped at the 17th of 44, `hooks` at the
33rd of 51, and each left a repository with a written tree and no commit —
`GIT` with a stamped `CLAUDE.md`, a bumped `version.md` and a changelog entry
that never became a commit; `SHVIA/.continue` the same, with `release.sh`. The
27 repositories behind the first failure never got their turn.

The cause was one line: `git add` returning non-zero under `set -euo pipefail`.
A guard meant to stop the script on a programming mistake stopped it on a fact
about one repository. Worse than the interruption is what it says about the
tool: a pass over fifty repositories that treats the first refusal as fatal will
always be a pass that ran halfway.

**Each repository is now applied by `apply_one`**, called with `set -e`
suspended and checking its own commands. A failure sets a message, rolls that
repository back to the state it was found in, and the loop continues. The run
ends with three lists — **applied**, **skipped with the reason**, **failed with
the error** — and a non-zero exit **after** every repository has been attempted.

**The refusal that killed both passes was correct**, and is now a named finding.
`GIT` and `SHVIA/.continue` carry `CHANGELOG.md` and `tools/git-hooks` in their
`.gitignore` — and `SHVIA/.continue`, which is named for the queue, ignores
`.continue` as well. The divergence is the `.gitignore`, not the add: golden rule
8 says everything is versioned and a new exception needs an ADR rather than a
silent line. `check` reports *"ignores files the standard tracks"* with the list,
and the apply modes skip the repository with the same sentence. **Never
`git add -f`.** The gate is narrower than the finding, and the difference is
measured rather than guessed: `git add` refuses an ignored path only when it is
**untracked**, so a repository that has tracked its changelog since before
someone added the line is not skipped for a problem it does not have.

**A push refused by a remote that moved is replayed once, and never forced.**
`EOP` refused: the remote had 36 commits this clone did not have. The retry
happens only when the tree is clean and our own commit replays onto the fetched
branch without conflict; then the push is tried again. A dirty tree, a
conflicting replay or a second refusal leaves the commit local and untouched, and
says so. No force, no `--force-with-lease`, no merge nobody verified — a refused
push is a decision about someone else's work ([ADR-018](docs/decisions.md)). The
fixture proves both directions: a remote that moved in a file the pass does not
touch replays cleanly; one that moved `version.md` — `EOP`'s case, and the common
one, because every delivery here bumps that file — conflicts, and the commit
stays where it is.

**Two details the rewrite got right only on the second try**, both found by a
four-repository fixture built to fail in four different ways, which is now how
this script is tested. `APPLIED` means committed *and* published: a commit
stranded by a refused push was appearing in both lists, which reads as success.
And `rollback_one` resets only the paths this pass wrote — the first version
reset the whole index, which would have unstaged whatever the person working in
that repository had already staged. That is somebody else's work, and none of
this script's business.

**One line of the classification changed for a reason worth recording.**
`git remote get-url origin` applies any `url.<base>.insteadOf` rewrite before
answering, and the question here is *which repository is this*, not *which
transport git will use*. The script reads `remote.origin.url` from the config
now, falling back to `get-url`. In this fleet the two agree everywhere today; the
fix is for the day they do not.

## 1.11.0 - `fleet-hooks.sh` becomes `fleet.sh`, with `echo` and `check` beside `hooks`

Installing 51 hooks in one afternoon proved the distribution works and left two
holes it could not fill. The first: the corrected rules reach nobody. Measured
across 54 repositories on 07/09/2026 — **`QUEUE-RULE` stamped in 1**,
**`LANGUAGE-RULE` in 1**, most still carrying the old single `RELEASES-RULE`
with the language section inside it, and 35 that do not mention `.continue/`
anywhere. `fleet-hooks.sh` distributed hooks; the echo blocks had no instrument
at all, which is why the queue item for stamping them had been open since
`1.8.0`. The second: nothing measures whether any of it is still true next
month. 51 hooks installed today become 3 again by attrition, and the only reason
anyone noticed the last drift was that a person went looking.

**One script with three modes, not three scripts.** The hard part was never
writing a file — it is deciding *which repositories may be written to*: the owner
on `origin`, the language of the repository, the exclusions that are written
down, the working tree that is mid-edit. That classification is identical for all
three jobs, and a second copy of it is precisely the failure this repository
exists to prevent. The rename cost nothing: the script was half a day old and
named in three documents.

- **`hooks`** — as before, and now `tools/release.sh` with them, wherever the
  copy carries the `repodocs:tool` marker.
- **`echo`** — the four blocks into `CLAUDE.md` and `AGENTS.md`, each replaced
  **whole between its markers, heading included**. That is what makes a block
  edited in place harmless and what lets the old two-subject `RELEASES-RULE` be
  replaced by the split pair; a block a repository does not have yet is inserted
  beside the ones it does. The `-PT` variant is chosen by the owner on `origin`,
  never by hand. The twins are diffed after stamping and the commit is abandoned
  if they came out different ([ADR-007](docs/decisions.md)).
- **`check`** — read-only, and it says so in its own header: it writes nothing,
  anywhere. Hooks enabled and identical to the standard, `release.sh` identical,
  the four blocks stamped, the twins identical below the H1, the default branch,
  `.continue/README.md` present, queue files not in git, and with `--releases`
  whether `version.md` has its Release.

**The first run found 258 findings across 54 repositories**, which is why the
report groups them by kind: they are a dozen things to fix once, not 258 things
to fix separately. Two of the twelve are new information rather than known
backlog — **8 repositories whose default branch is not `master`**
([ADR-015](docs/decisions.md)) and **17 with a `.continue/` and no `README.md`**
in it (conventions §2).

One check was wrong on its first run and is worth recording: it read the branch
**checked out** rather than the remote's default, and reported a topic branch as
an ADR-015 violation. A conformance report that flags normal work is a report
that gets skimmed. It reads `refs/remotes/origin/HEAD` now, and when the clone
was never told, it says so as a **note** rather than counting a finding — the
number at the bottom is meant to be acted on.

## 1.11.0 - `release.sh` carries a provenance marker, so a pass can tell it from a repository's own

The hooks have carried `# repodocs:hook` since `1.9.0`, and it is what lets a
fleet pass regenerate a copy that came from here while never touching one a
repository wrote for itself — EOP's `commit-msg` is the case that rule exists
for. `tools/release.sh` had no such line, so a fleet pass had two options and
both were wrong: overwrite whatever it finds, or leave the `1.9.1` fix
undistributed in 51 repositories.

`# repodocs:tool` closes that. A copy carrying it is regenerated; one without it
is left alone and reported. A copy generated here before the marker existed is
recognised by what only a generated copy has, the same way the hooks handle
their own pre-marker copies.

This is what makes the `release.sh` queue item close by the same command as the
hooks rather than by a second pass: the fix that stopped it publishing a Release
into a fork's upstream now travels.

## 1.11.0 - pre-push says which queue files are not in git

The queue's whole recovery story — *"it is git-tracked on purpose, so
`git checkout HEAD~1 -- .continue/` brings it back"* — assumes the file is in
git. Checked against the repository where the queue was emptied: it was not.
`git log --all --diff-filter=D -- .continue/` in `notes` returns **nothing**. No
file was ever deleted from that folder in any commit, because the drafts had
never been committed. They entered git at `0.2.1`, the restore. The 1,338-line
brief survived because the owner had a copy elsewhere.

That is worth stating plainly, because it also settles what a hook can and cannot
do here. A `pre-commit` guard refusing a commit that deletes from `.continue/`
was proposed and would not have fired: there was no deletion to see, and the
commit that emptied the queue touched `CLAUDE.md`, `README.md` and `NOTICE`, so
any "did this commit do real work" escape clause would have passed it too. It
would also refuse the normal close of an item in **this** repository, where
producing a queue item usually produces a document. Too weak where it was aimed,
too strong everywhere else, and in between it asks a script to decide whether a
thing was built — which is the question the norm exists to put to a reader.

What is mechanical is the gap the incident actually exposed. `pre-push` now warns
when `.continue/` holds files git does not track, naming them, at the moment work
is published to the default branch. **A warning and never a refusal** — an
untracked draft is a normal state of work in progress, and a guard that fires on
normal work is a guard that gets bypassed, which is the same argument this
standard already makes about test suites in `pre-push`.

## 1.10.3 - the queue's own review header was five versions stale

`.continue/README.md` opened with *"Last reviewed 05/09/2026, repository at
`1.8.0`"* while the repository stood at `1.10.2` — through eleven versions, two
new ADRs and three edits to that same file, including the ones that rewrote how
the queue works.

Golden rule 6 is *"a document made stale by a change is fixed in the same
pass"*, and rule 5 exists because a document that ages in silence is worse than
a missing one: it has the authority of being written down. The file that says so
was the one drifting, and the drift was in the line a reader uses to decide
whether to trust the rest of it.

There is no mechanism behind that header — it is a date somebody types. Every
other freshness claim in this fleet has one: `version.md` has two git hooks, the
Releases have a workflow and an idempotent script, the twins have a `diff` in
the checklist. A conformance check that reads it, alongside the other things
that rot quietly, is what the queue's next item is for.

## 1.10.3 - the sentence that emptied the queue survived in `docs/README.md`

ADR-021 corrected the rule in five places and there were six. `conventions.md`
§1, the two golden rules of the twins, both queue `README.md`s and the new
`QUEUE-RULE` block were all fixed on 07/09/2026. `docs/README.md` — root and
skeleton — was not, and it carries the sentence in the form the agent quoted:

> *"If a queue item needs half a page, it is in the wrong place: write it here
> and leave one line and a pointer in the queue."*

with a routing table whose queue row read **"something still to be done, in one
line"**. Read together they say a specification longer than one line does not
belong in the queue, which is the instruction that emptied `notes`. And this is
the copy that would have kept saying it in **every repository created from the
skeleton**, indefinitely, while the corrected sentence sat three files away.

The miss is the ADR's own thesis arriving by post. A rule stated in six places
is a rule with six chances to be stale, and the pass that corrects five of them
leaves the sixth carrying the full authority of a document nobody suspects. It
was found by an audit that went looking for the exact string, which is the only
way this class of thing is ever found.

The queue row now reads **"at any length, in whatever shape"**, the exit
condition and the definition of *produce* are stated in place, and the
half-a-page rule keeps its job with its reach bounded: it is about a record that
ended up in the queue, and that is the whole of it.

## 1.10.2 - the `ACTIVE` pages in the incident report were declared `PROPOSED`

The `1.10.1` entry closes by naming a second failure in `notes`: the three pages
that replaced its queue *"were all declared `ACTIVE` — an architecture, a product
scope and a roadmap for an application with no code"*. That is false, and it was
false when it was written.

`docs/product.md`, `docs/architecture.md` and `docs/roadmap.md` all declare
**`PROPOSED`** on line 3, each under the sentence *"Nothing described here has
been built yet"*, each pointing at the queue as the authority on intent while
both documents exist, and each saying a section becomes `ACTIVE` when its code
exists. The repository had already answered the question correctly, in its own
words, before this one asked it.

**How the wrong answer was produced**, because it is the reusable part: a single
`grep -m1 -o` over each whole file with an alternation of every status token.
The three pages contain the word `ACTIVE` — in the sentence explaining when a
section becomes it — and the pattern reported that instead of the declared
status. Nothing opened the files. The finding then travelled from a shell
one-liner into a changelog entry, a commit message and a sentence spoken to the
owner, without ever touching the document it described. It is recorded in
[conventions.md §6](docs/conventions.md#6-measurement-traps-already-paid-for)
with the others: read the header line, not the file, and open the file before a
status becomes a claim about someone else's work.

**The clause the mistake produced is kept**, because it is right independently of
how it was arrived at: a plan that has to be visible in `docs/` before it is
built is `PROPOSED`, never `ACTIVE`. `notes` is where it was already being
practised, which is a better provenance than the one `1.10.1` gave it.

History is not rewritten: the `1.10.1` entry stays as it was published, and this
is the correction that travels with it.

## 1.10.1 - the rule that failed was the one rule that had never been an echo block

`1.10.0` fixed the norm. This measures how much of the fleet the fix would have
reached, and the answer was: almost none of it.

Of the 52 repositories the hooks reached, **2 carried any version of the queue
rule** — `ai-memory-web` and `notes` — and **35 never mention `.continue/` in
their `CLAUDE.md` at all**; 24 have no such folder. `COMMIT-RULE`,
`RELEASES-RULE` and `LANGUAGE-RULE` are echo blocks and travel; the queue rule
lived in the skeleton's `CLAUDE.md`, which is **copied once at creation and never
regenerated**. So it reached repositories created from the skeleton, and stopped
there.

That is why the correction had to be more than a correction. `notes` — the
repository where the queue was emptied — was created from the skeleton **that
same morning**, hours before `1.10.0`. Without a block, the fixed sentence would
have sat here while the repository that had already demonstrated the failure kept
the text that produced it, and every repository created before today would keep
nothing at all.

`QUEUE-RULE` and `QUEUE-RULE-PT` are now blocks, stamped into this repository's
twins and the skeleton's, and into `notes` by hand. They carry the whole rule and
not a summary: the single exit condition, the definition of *produce*, the
`tela.md` example in the owner's own words, the bound on the half-a-page rule,
the language clause — and the sentence that is the actual instruction, **never
empty this folder as tidying**.

One clause is in the block and not in `1.10.0`'s prose, because the incident
produced it: **if a plan has to be visible in `docs/` before it is built, it is
`PROPOSED`, never `ACTIVE`.** The three pages that replaced `notes`' queue were
all declared `ACTIVE` — an architecture, a product scope and a roadmap for an
application with no code — which is [ADR-008](docs/decisions.md) being satisfied
in letter and inverted in effect. The label existed; nothing said which one a
plan gets.

## 1.10.0 - a draft in the queue is written in the language it is thought in

The English rule was one of the three the agent cited before emptying a new
project's queue, and on that point it was not wrong either. A Portuguese brief
in `.continue/` is repository content under [ADR-014](docs/decisions.md), and
*"everything new, and every edit to an existing document, comes out in English"*
made translating it look like the correct next move — with the move that
suggests itself being to `docs/`, which turns a plan into a claim that the work
exists.

[ADR-022](docs/decisions.md) removes that step. **`.continue/` is written in the
language its author thinks in**, and becomes English (US) when the work is
produced and the document moves to `docs/`. The English rule governs the record;
it does not govern the drafting.

The reason is the reader the rule exists for. A queue draft does not have one
yet: it is the author working out what to build, before the thing exists, and it
may never ship — the project can be dropped, or the design can change three
times before a line is written. Translating it is a cost paid on behalf of a
reader who may never have anything to read, and paid at the worst moment, while
the idea is still being formed.

**The boundary is the folder and nothing more.** `docs/`, `README.md`,
`CHANGELOG.md`, commit messages, pull requests, issues, release notes and code
comments are English exactly as before — a repository is not Portuguese because
its queue is. And nothing is rewritten in either direction: an English
`.continue/README.md` that already exists stays English, the same way an old
Portuguese document stays Portuguese under ADR-005.

The carve-out count goes from two to three, corrected in the same pass in
`conventions.md` §8, both echo blocks, the twins here and the skeleton's. The
three are kept as three rows because they are bounded differently — **what kind
of text** (end-user strings), **which repository** (the Blue3 internal set), and
**where in the lifecycle** (the queue). Only the third is temporary by
construction: every document it covers is meant to leave, and crosses into
English on the way out. A carve-out whose contents all eventually enter the rule
is not a hole in the rule.

`LANGUAGE-RULE-PT` gains the queue clause too, in Portuguese. A repository that
is Portuguese throughout still needs to be told that emptying `.continue/` is
not tidying — the two failures are independent, and that block is the only one
some repositories read.

## 1.10.0 - the queue empties by production, and by nothing else

On 07/09/2026, in a new repository, the owner asked an agent to **produce**.
`.continue/` held one document: a 1,338-line brief, in Portuguese, describing
work that did not exist yet. The agent reasoned that producing here meant
something specific — a draft in the queue, in Portuguese, 1,338 lines; the rules
say an item needing half a page does not belong in `.continue/`, that a decision
becomes an ADR in the same pass, and that everything is English — and converted
the queue into the record. It emptied the folder.

**Every step of that reasoning cites this norm correctly.** The agent did not
ignore the rules. It followed three of them into a place none of them meant to
go, and the reason it could is that §1 contained two triggers and never said
which wins:

| Sentence | Trigger |
|---|---|
| *"A document leaves `.continue/` for `docs/` the moment it describes something that already exists"* | Existence |
| *"If an item needs half a page, it is in the wrong place. Write it in `docs/`"* | Size |

For a short note about finished work they agree. For a long specification of
unbuilt work they point in opposite directions — and the size one is the
actionable half, because it names a destination. ADR-004 states it even more
absolutely: *"detail never lives in the queue."*

**The root cause is structural.** Every rule about the queue in this standard was
written while looking at a queue that was **residue**. This repository's own
`.continue/README.md` opens with *"Nothing, in the sense of unfinished work"* —
repodocs shipped what it planned, so its queue holds leftovers and emptying it is
tidying. In a new project the queue is the opposite: nothing is built, so the
queue **is** the project, and the same rules delete it. The norm was generalised
from the one case where the queue was worth the least.

[ADR-021](docs/decisions.md) makes existence the **single** exit condition.
Length, age, language, untidiness, a session ending and an agent who would have
written it differently are not exit conditions and do not become one.
**"Produce", applied to a queue item, means making the thing exist** — not
editing the document, not translating it, not promoting it. The owner's own
example is in the norm now: `tela.md` says *"a black screen with a yellow ball
in the middle"*, and it leaves the queue when there is a black screen with a
yellow ball. Removing the document is the last step of the commit that carries
the work, never a step of its own.

The half-a-page rule keeps its job and loses its reach: it is about a **record**
that ended up in the queue, and has no opinion on the length of a specification
of unbuilt work. A long queue item is a project with a lot still to build.

**The lost file is the smaller half of the damage**, and the recoverable one —
`.continue/` is git-tracked exactly so that `git checkout HEAD~1 -- .continue/`
brings it back. The larger half is what replaces it: a `docs/` page describing a
screen nobody built, indistinguishable from a page describing one that exists,
carrying the authority of the record. That is what ADR-008's status labels exist
to prevent, arriving through a door nobody had closed.

## 1.9.4 - creating the missing changelog would have created a second one in 23 repositories

`1.9.3` taught `fleet-hooks.sh` to create `CHANGELOG.md` where a repository had
none. The measurement behind it was wrong in a way the first pass could not see:
of the 34 repositories without the file, **23 keep their changelog as a section
inside `version.md`** — the markdown-shaped variant blessed by
[ADR-012](docs/decisions.md), which several of them carry with a full history
under a `## 3. Changelog` heading.

Creating `CHANGELOG.md` beside that produces two changelogs in one repository,
which is the failure this standard names about a translated `README` pair, in
the one file that decides what a version means. It was not hypothetical: the
`samirhvbr` regeneration ran before this was caught and created exactly that
duplicate, which is reverted in that repository in the same pass.

The three cases are now told apart. A repository with `CHANGELOG.md` gets the
entry. A repository with **no changelog anywhere** — 13 of them — gets the file
created. A repository whose changelog is inside `version.md` gets **neither**: no
entry, no second file, and a line in the report saying so.

Writing into the `version.md` section instead was considered and rejected. Those
sections use a per-repo heading style (`### \`X.Y.Z\` — date — subject` in three
different flavours), so a script writing `## X.Y.Z - description` into them would
produce an entry that does not match the file it is in. Moving those 23 to the
standard location is a migration with its own decisions, and it is in the queue
where a migration belongs — not smuggled into a pass about hooks.

## 1.9.3 - the fleet script creates the changelog it has been assuming

34 repositories of the fleet — two thirds of the ones the hooks reached — have
no `CHANGELOG.md` at all. The rule that the entry's `## X.Y.Z - description`
heading **is** the commit subject therefore held only where the file happened to
exist, and the first fleet pass wrote its entry in 16 repositories and skipped
it in 34, reporting them at the end and doing nothing about it.

That report was the right output for a first pass and the wrong place to stop.
The file is not optional in this standard: the entry written before the commit
is what stops the subject from being invented at `git commit` time, and a
repository without the file has no place to write it.

`fleet-hooks.sh` now creates it with the standard header — in that repository's
language — and this pass's entry as the first record. **Earlier versions are not
back-filled**, and the header says so in place: they are in `git log`, and
reconstructing them into entries now would produce a plausible history rather
than a true one. The same reasoning SSHVTERM-API applied to its missing Releases
an hour earlier.

The classification also stops reading a *missing* `CHANGELOG.md` as an in-flight
edit — a file that does not exist cannot be mid-edit, and the check that guards
against folding someone's work in progress into a commit about hooks was
answering a different question for the 34.

## 1.9.3 - the skeleton's changelog header describes a model that was switched off in September

Two sentences at the top of `templates/skeleton/CHANGELOG.md` were wrong, and
they were being copied into every repository created from the skeleton.

The format line asked for `versão - comentário em português`. That was true
until 03/09/2026 and has been false since [ADR-014](docs/decisions.md): the
commit message is repository content, and it is English (US) — with the one
carve-out that is the Blue3 internal set, where the whole repository is
Portuguese, and a repository there is not reading this line to find that out.

The second sentence called the file *"the handoff artefact between whoever does
the work and whoever commits it"*. That is a description of the COMMITTER model,
which was switched off across the fleet on 03/09/2026
([ADR-016](docs/decisions.md)). There is no handoff and no second party: the
agent that writes the entry is the agent that commits it. Leaving the sentence
in place told every new repository to expect a step that no longer exists.

What replaces it is the reason the entry is written first, which is the part
worth carrying: the sentence that lands in `git log` is one that was weighed,
rather than improvised at `git commit` time.

## 1.9.2 - pre-push refused a branch deletion, because it never read what it was given

`git push origin --delete main` was rejected with *"version 1.9.x is already on
master"*. There was no version in that push at all: a deletion publishes
nothing, and the hook asked the version question anyway.

The cause is that `pre-push` never read its stdin. Git hands the hook one line
per ref — `<local ref> <local sha> <remote ref> <remote sha>` — and that line is
the only thing that says whether a push is a version bump, a deletion, a tag or
a topic branch. Ignoring it makes every push the same push, and the check that
belongs to exactly one of them fires on all four.

It now reads the refs and checks the version only when the push **updates the
default branch** with a real commit — an all-zero local sha is a deletion,
`refs/tags/*` is a tag, and any other branch is not what
*"the `version.md` on GitHub"* refers to. With no stdin at all it falls through
to the full check, so nothing that worked before stops working.

**This shipped to 51 repositories two hours before it was found**, in the same
pass that installed the hooks, and it was found the way this kind of thing gets
found: by hitting it. `samirhvbr` needed a redundant `origin/main` deleted after
its default branch was fast-forwarded, and the guard that exists to protect the
version refused an operation that has no version. A guard that refuses what it
was never about is a guard that gets bypassed — which is the argument this
standard already makes about test suites in `pre-push`, arriving from the other
direction.

The fix reaches the fleet the way the hook did: `tools/fleet-hooks.sh`
regenerates any copy carrying the provenance marker.

## 1.9.1 - release.sh asked git for the repository and git answered the upstream

`tools/release.sh` resolved the repository with `gh repo view --json
nameWithOwner` and no argument. With one remote that is right. With two it is
whatever gh's own precedence picks, and in a fork carrying an `upstream` remote
it picks the **upstream** — so the script that publishes a Release for our
`version.md` addressed somebody else's repository.

It was caught in `000/hermes-agent`, which has `origin` on `samirhvbr` and
`upstream` on `NousResearch`. `release.sh` asked for
`NousResearch/hermes-agent` and got `HTTP 404: Not Found`. **The 404 is luck,
not a guard.** In a repository where we hold write access to the second remote —
a fork inside an organisation we belong to, a mirror — the call succeeds, the
Release lands somewhere it does not belong, and nothing in the output says so:
the script would have printed `published` and been wrong.

The fix reads `origin` explicitly and only falls back to gh's guess when
`origin` yields nothing shaped like `owner/name`. `origin` is already the
authority everywhere else in this standard — `pre-push` compares against
`origin/<default>`, and `fleet-hooks.sh` decides whether a repository is ours by
the owner on `origin`. This was the one place that asked a different question.

One repository in the fleet has a second remote today, which is why this cost a
404 and not an incident. It is fixed here and in the skeleton; the copies
already distributed are listed in the queue, because a tool with a known defect
sitting in fifty repositories is not something a changelog entry closes.

## 1.9.0 - a fleet script installs the hooks where the convention is already in force

The hook that checks the version is worth what it enforces, and on 07/09/2026 it
enforced nothing in 55 repositories out of 58. `core.hooksPath` was set in three
clones — repodocs, `SSHVTERM-DESKTOP`, `ai-memory-web` — and four repositories
carried `tools/git-hooks/` at all. Everywhere else the commit rule was a
paragraph in a `CLAUDE.md`, which is what a paragraph becomes at the end of a
long session: advisory.

`tools/fleet-hooks.sh` walks the fleet, classifies every repository with a
reason, and by default changes nothing. What it refuses to do is the part worth
reviewing:

- **It never touches a repository that is not ours.** The owner on the `origin`
  remote decides — `samirhvbr` and `BLUE3-ISP`, nobody else. That excludes
  `tiago-razera`'s repositories and the thirty-odd upstreams we have clones of,
  where the host's conventions win ([ADR-019](docs/decisions.md)).
- **It never overwrites a hook a repository wrote for itself.** EOP is the case
  this protects: its `commit-msg` runs the same version check through its own
  lint, has a toolchain behind it, and is stronger than this one. A hook
  generated from here before the provenance marker existed is recognised by its
  `HOOK_ESCAPE_VAR` line and regenerated anyway — `ai-memory-web` is that case,
  and its renamed escape variable is preserved because that name is written into
  its own documentation.
- **It never installs into a repository that writes someone else's subjects.**
  The window is the last five non-merge commits, and the width was measured, not
  guessed: at twenty it reaches back past 03/09/2026 and reads six fleet
  repositories' own pre-rule history as evidence against them (8/20 each). At
  five, the fleet scores 4/5 or 5/5 and `strix` and `pve-manager` score 0/5.
- **It never commits a file the working tree is mid-edit on.** `BLUE3-INTRANET`
  is exactly that case today, with an uncommitted bump — the repository whose
  defect motivated the check is the one the script declines to touch, and it
  says so instead of quietly folding an in-flight change into a commit about
  hooks.
- **It stops at a refused push** and prints git's own output
  ([ADR-018](docs/decisions.md)).

Each selected repository gets one commit — the two hooks, the bump and the
changelog entry, in that repository's language ([ADR-020](docs/decisions.md)) —
and **that commit goes through the hook it installs**. A repository that would
refuse its own installation says so and is rolled back to the state it was
found in, rather than being forced.

Two failure modes were found by the trial run on one repository, which is why
the trial exists: a pathspec commit cannot reach an untracked file, and
`git diff` is blind to one, so the first attempt reported "already current" and
the second refused the pathspec. Both are fixed, and the rollback that returns a
repository to its found state was written in the same pass.

## 1.9.0 - the hook exempts every subject git wrote, not only a merge

The version check landed with one exemption — a merge, detected by `MERGE_HEAD`
— and that was the exemption its author happened to think of. EOP had the
answer already. Its `commit-msg` has been checking the same thing since
04/09/2026, against `version.md`, reached independently and written in
Portuguese in its own file, and it exempts by subject prefix: `Merge`, `Revert`,
`fixup!`, `squash!`. That list is not longer for the sake of it. A revert's
version is in the commit it undoes, a fixup line is consumed by the rebase that
lands it, and neither is a sentence a person wrote.

The list here is now EOP's, plus `amend!` and the `MERGE_HEAD` check that catches
a merge whose subject was rewritten by hand. Taking the tested list rather than
inventing a shorter one is the same rule this repository applies to its own
documents: two implementations of one rule is how a rule ends up with two
versions, one of them wrong.

Worth recording for the fleet pass that follows: EOP is the one repository where
the norm was **not** advisory, and it is also the only one whose hook this
standard must not overwrite. The check it runs is stronger than this one — it
goes through the same lint the PR title goes through — and it has a toolchain
behind it.

## 1.9.0 - the Blue3 internal repositories are Portuguese, and the norm finally says so

The English rule was never about English. It exists for a reader — the
collaborator or the tool that does not read Portuguese and meets our text first
— and [ADR-019](docs/decisions.md) already drew one boundary where that reader
belongs to someone else: a repository we do not own. The Blue3 internal set is
the other place the reader is absent, and for a blunter reason. Nobody outside
the company opens those repositories. They are an intranet and an ISP's
operational tooling, and much of what is written into them is operational
reasoning rather than documentation: an incident, a queue, a runbook, the
sentence explaining why a migration ran at 02:00. There the precision of the
sentence *is* the value, and it is written and read by the same people.

None of that is new. What is new is that this repository knows it. The exception
was already being practised — BLUE3-INTRANET carried it inside its own
`CLAUDE.md`, in an *Idioma* section placed deliberately outside the echo block so
a regeneration would not overwrite it — and the norm here said the opposite,
with no record of the difference. A fleet norm contradicted by the fleet, and
unaware of it, is the same failure ADR-002 was written for.

[ADR-020](docs/decisions.md) draws the boundary at **the owner on GitHub**, not
the folder on disk and not the name: everything under `BLUE3-ISP`, plus
`samirhvbr/blue3-intranet` and `samirhvbr/blue3-ai-login`. `samirhvbr/meuip` is
named in the norm as *not* in the set, because it sits in the same working
folder and the folder is exactly what the boundary is not. One line decides it:
`git remote get-url origin`.

**Only the language changes.** `X.Y.Z - description`, the changelog heading that
is the subject, no Conventional Commits prefix, one subject per commit, the bump
in the same commit, the agent commits and pushes — all unchanged, and code
identifiers stay English. Nothing mechanical changes either: `commit-msg` never
checked the language and cannot, so the carve-out costs no code.

**B3DEV is deliberately not in the set**, and that is a correction rather than an
omission. Those repositories belong to `tiago-razera` — we are guests, and
ADR-019 already answers them: the host writes Portuguese, so we write
Portuguese. The owner's global preferences had listed BLUE3-INTRANET and B3DEV
side by side as one exception. They are two different rules that happen to agree,
and collapsing them would have built a second, weaker route to an answer we
already had.

The cost is the count. *"One carve-out, and only one"* appears in four places and
is now false in all of them; `conventions.md` §8, the `LANGUAGE-RULE` block, the
skeleton's twins and this repository's own twins are corrected in this pass, and
ADR-014 carries the amendment note in the house style. The two are kept as two
rows rather than a list because they are different in kind: the first is about
*what kind of text*, in any repository; the second about *which repository*, for
all of its text.

The echo block could not stay one block. A `LANGUAGE-RULE` reading *"everything
here is English (US)"*, stamped into BLUE3-F1, contradicts the norm in the
repository it governs — and an agent that reads the first line and acts on it is
behaving correctly. `templates/echo-blocks/LANGUAGE-RULE-PT.md` is the variant
those repositories get. It carries the same marker name, so a regeneration
replaces whichever variant is present, and it is **written in Portuguese**:
it is not this repository's prose but the text of a Portuguese repository in
transit, the same category as the end-user strings of the first carve-out.

## 1.9.0 - the commit-msg hook checks the subject version against version.md

The hook has been checking the *shape* of a commit subject since `1.0.0`:
`X.Y.Z - comment`, no Conventional Commits prefix, no vague or three-character
comment. A well-formed subject can still carry the wrong number, and nothing
looked at the number itself — not `commit-msg`, which never read `version.md`,
and not `pre-push`, which reads the file but never the subject. Between them
they proved that a version exists and that a subject has a version in it, and
never that the two are the same version.

Two repositories were living in that gap on the day this was written, and both
were found by a survey rather than by a person noticing:

- **BLUE3-INTRANET** had four consecutive commits subject-stamped `1.8.13` while
  `version.md` at `HEAD` still read `1.8.11`. The bump was sitting in the working
  tree, uncommitted, so `1.8.12` never existed in the history at all. Every one
  of those four subjects would pass the old hook.
- **SSHVTERM-API** stamped `2.0.14 - …` — the version of SSHVTERM-DESKTOP, the
  repository next to it. Its own `version.md` went `1.2.0 → 1.2.1` inside that
  same commit, correctly, and the subject named neither number.

Both are the failure the norm has always described (*"the version comes from
`version.md`, bumped in the same commit"*) and neither was mechanically
detectable, which is why the norm alone was not enough.

`commit-msg` now reads `version.md` **from the index** and refuses a subject
whose version is not the one the commit carries, naming both numbers. The index
and not the working tree, because the index is what the commit will contain:
that is what makes a bump staged in this commit pass, a later commit of the same
block repeat its version and pass, and a bump left unstaged fail — the commit
genuinely does not carry it. A missing `version.md`, or one with no semver,
degrades to a warning, the same way `pre-push` degrades when it cannot reach the
remote: a guard that blocks the work when it cannot measure is a guard that gets
switched off.

**A merge commit is now exempt**, and that is a new exemption rather than an
oversight being fixed. Its subject is written by git, it carries no version of
its own, and the old hook refused it — which is one reason the hook was enabled
in three clones out of fifty-eight. A guard that fires on `git merge` is a guard
that gets bypassed with `--no-verify`, and `--no-verify` switches off every
guard at once.

The error message loses the words *"in English"*. The hook never checked the
language and cannot: what it enforces is the shape and the number. Where the
language rule lives is now what it points at.

## 1.8.3 - the skeleton carries its own map of what came from repodocs

A repository created from the skeleton has always known the rules and never known
their shape. `CLAUDE.md` told it where the norm lives; `docs/README.md` told it the
norm is deliberately not copied. Neither said which of the thirty-odd files in the
new repository arrived from the standard, which of them are mirrors that get
overwritten on the next fleet pass, and which are now simply that repository's own
files to edit. Every one of those questions had an answer, and every answer lived
here, in a repository the new one only links to.

That gap is not theoretical, and the queue records where it lands. The `1.5.1`
sweep found heading variants of an echo block across the fleet — blocks that had
been *edited* in place rather than regenerated, by someone with no way to know the
difference. An echo block edited locally is worse than one left alone: the next
regeneration overwrites the edit silently, and until it does, that repository is
following a rule no other repository has.

`templates/skeleton/docs/repodocs.md` is the answer, and it ships inside every new
repository rather than staying here. It carries the mental map of the relationship
— what travels out of repodocs **by copy** (the skeleton, once, and then it stops
being repodocs' business), what travels **by stamp** (the three echo blocks,
regenerated and never edited), and what **never travels** (`conventions.md`, linked
only, because a rule copied into sixteen repositories is a rule with sixteen
versions) — then the manifest of every file with what is actually lost when it is
missing, an adoption order for a repository that already has history, and the table
of which question is answered upstream rather than locally.

**It repeats none of the bootstrap procedure**, and that restraint is the whole
test of whether this repository believes its own first golden rule. The placeholder
table, the per-repo decisions and the conformance checks stay in `docs/runbook.md`,
which the new page links; a second copy of them would have been exactly the failure
the standard exists to prevent. What the page owns is what had no owner before: the
manifest, the three merge rules for a retrofit, and the regeneration rule.

The `.claude/` row of the manifest names the trap this fleet has already paid for
once — a `cp -r` without the trailing `/.` produces a repository that looks
conforming and has no permission posture. The retrofit section makes the same kind
of failure explicit for an existing repository: never overwrite a file the
repository already had, keep an existing document that already answers the
question, and do not restart the version at `0.1.0` on a repository already at
`2.4.0`.

One intended divergence is created here: the skeleton now has a `docs/` page with
no twin in this repository's own `docs/`. It is correct that it has none — repodocs
does not need a map of its relationship to itself — and `templates/README.md`
records it so the next honesty check does not read it as drift.

## 1.8.2 - the settings comment rule names the one block that rejects it

`.claude/settings.json` is plain JSON with no comment syntax, so the fleet
documents its profile with `_comment_*` keys. The convention was never written
down because it had never failed — and it had never failed because no repository
in the fleet had a `hooks` block.

SHVIA-DESKTOP became the first, with the `PostToolUse` check of the `impeccable`
skill, and the comment placed inside `hooks` was dropped at every startup with
`Unknown hook event "_comment" was ignored`. `hooks` is the only block whose keys
are a closed enum of event names; everywhere else the schema declares
`additionalProperties`, which is why the `_comment_profile` at the top level and
the `_comment` inside `permissions` — both in the skeleton — have never warned.

What made it survive is that nothing broke: the hook ran correctly the whole
time, and only the stray key was discarded. The warning was the entire symptom.
Fixed there in `d362855` by moving the string to a top-level `_comment_hooks`.

Neither `settings.json` here needed a change — this repository and the skeleton
both have no `hooks` block, so both were already correct. §7 gains the rule for
the repository that adds one.

## 1.8.1 - the written-instruction probe reads the community profile, not a guessed path

Running the `1.8.0` procedure against a real upstream found its first step wrong.
It probed `repos/OWNER/REPO/contents/CONTRIBUTING.md`, which is one guess at one
path: `cli/cli` keeps its `CONTRIBUTING.md` under `.github/`, so the probe
returned a raw 404 blob and the check silently reported "no written instruction"
for a repository that has one. A signal that fails closed in the wrong direction
is worse than no signal, because the next step down — observed practice — then
gets treated as authoritative.

`gh api repos/OWNER/REPO/community/profile --jq '.files'` is one call and returns
the contributing guide, the pull request template, the issue template and the
readme with their real URLs, wherever they live. Verified against `cli/cli`
(`.github/`) and `rails/rails` (root).

The `LANGUAGE-RULE` block is untouched: it carries the ordering of the signals,
not the commands, so it did not inherit the defect and does not need a fourth
regeneration.

## 1.8.0 - the norm gains the guest clause: outside the fleet, the upstream's conventions win

`1.3.0` put everything in English (US) — documents, commit messages, pull
requests, issues — and ADR-014 quoted the instruction that produced it: *"todo
commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*. That rule was
written for the fleet, fifty private repositories with one owner, and it never
had to say so because nothing else was in view.

It says so now. Read literally, the rule sends an English pull request into
`tiago-razera`, a repository that works entirely in Portuguese. That is the wrong
output for the right reason: the English rule exists so a collaborator who does
not read Portuguese meets English first, and applied to someone else's repository
it produces the exact opposite — the one contribution in their log that their own
maintainers have to translate. A norm that makes us a worse guest is a norm
applied outside its scope.

[ADR-019](docs/decisions.md) draws the boundary. **The English (US) rule governs
the repositories we own; in a repository we do not own, the host's conventions
govern — the language and the commit shape both.** `conventions.md` §8 gains the
procedure: a written instruction first (`CONTRIBUTING.md`, a template, a
contribution section), then the last ~20 merged pull requests, then the issues,
then the log. A written instruction beats observed practice; below it the clear
majority decides. **When it cannot be determined, the house rule stands: English
(US)** — a private repository, an empty history, no network and a genuinely mixed
log all land in the same place, because unverifiable is not a licence to guess.

The commit shape travels with the language, and it has to: `X.Y.Z - description`
reads as noise in a repository with no `version.md` of ours, and there is no
version there for us to bump. Our versioning rules govern our remotes, not every
remote we can push to.

**It is a scope boundary, not a carve-out**, and that distinction is what keeps
the rest of the norm intact. The carve-outs answer *what kind of text* stays
Portuguese inside our repositories; this answers *whose repository* the text is
going into. The count is still one, and every document that says "one carve-out,
and only one" is still literally true — six files that would otherwise all have
needed rewording. Merging the two ideas would have made the English rule look
negotiable at home, which it is not.

## 1.7.0 - the human gate is a refused push, and the rule that said otherwise leaves the fleet

`1.5.0` said the agent commits and pushes. It never said where a person is still
required, and the gap produced a wrong answer within hours.

SHVIA-WEB carried one line from the COMMITTER era — *"Nada é commitado sem revisão
humana"* — which back then meant "the robot must not publish unreviewed work". Read
next to ADR-016 it says the opposite of ADR-016: if nothing may be committed without
review, an agent cannot commit its own delivery, and the delivery stops in a dirty
tree. Reconciling it, this session proposed *"nothing reaches `master` without human
review"*, reasoning that the repository reviews at merge, and flagged it as a
judgement made on the owner's behalf.

**The owner rejected that reading**, and the correction is the substance of this
version: commits and pushes both happen on **every** delivery, and review is not a
checkpoint the work waits at. The gate is a **refused** push — conflict,
non-fast-forward, protected branch. There the agent stops and says so; it does not
force, does not rewrite history to get past it, and does not invent a merge
resolution it has not verified.

[ADR-018](docs/decisions.md) records it. The gate sits there and nowhere else because
a refused push is the only one of the three moments that is *about someone else's
work* — someone changed the same lines, or a rule says this branch is not yours to
move. A gate on the commit stops the work existing; a gate on a clean push stops it
being visible. Only the third is a decision with another person on the other side,
and that is the one an agent should not take alone.

The `COMMIT-RULE` block gains the clause and is regenerated — the third regeneration
in a day. The phrase *"nada é commitado sem revisão humana"* leaves the fleet, because
under this ADR it is false.

## 1.6.0 - the bump clause gets a written escape hatch, because one repository already had one

`1.5.0` stated the bump as unconditional — *"the version taken from `version.md`
and bumped in the same commit"* — and `1.5.1` stamped that sentence into 147 agent
files. In 49 repositories it was right. In one it was false on arrival.

**SHVIA-WEB has not bumped in the commit since 29/08/2026, on purpose.** Its agent
writes the changelog entry with a `## (versão no merge) - description` placeholder
and the number is stamped at merge by `scripts/versao-no-merge.sh --apply`, read
from the remote. The reason is measured, not stylistic: **four `version.md`
collisions in a single day, between four parallel sessions.** A worktree isolates a
directory, not a number, and that repository has twenty of them live — a shape
nothing else in the fleet has.

So the block sat in that file next to a rule saying the opposite. A session working
there found two instructions governing the same act, could not tell which one won,
and stopped to ask instead of picking one. That is the right outcome and also the
whole diagnosis: **an instruction that needs a human to adjudicate it is not an
instruction.**

[ADR-017](docs/decisions.md) amends ADR-016. **The bump is the one clause a
repository may override, and only in writing** — its own documentation has to state
the alternative and state why. Everything else is unconditional: the changelog entry
first, the `X.Y.Z - description` subject, English (US), no Conventional Commits
prefixes, one subject per commit, nothing reported as finished before it is
committed.

The bump is singled out because it is the only clause whose correctness depends on
the repository's *shape* rather than on the norm. Twenty parallel worktrees make
in-commit bumping collide; one working tree does not. Every other clause is about
how a change is described and when it is recorded, and none of that varies with how
many worktrees a project has. "In writing" is the entire condition, the same
construction [ADR-015](docs/decisions.md) already uses for the default branch: an
undocumented override is not an exception, it is a repository quietly disagreeing
with the norm, and the next session cannot tell those apart.

**This is the first real exercise of the delimited-block design.** ADR-016 argued
for it against per-repo prose on the grounds that a fleet-wide correction should be
one pass rather than an archaeology. The correction arrived a day later, and the
argument holds: one edit here, regenerated everywhere.

The honest cost, recorded because it is a real one: a rule with an escape hatch is
weaker than one without, and this hatch was cut the day after the rule. The
alternative was worse — a block that is provably false in one repository teaches
every reader that the block is approximately true, and an approximately-true
instruction is one nobody stops at.

## 1.5.1 - the COMMIT-RULE pass over the fleet is done, and the ADR-007 twins with it

`1.5.0` decided that the agent commits and shipped the `COMMIT-RULE` block, but
left the pass over the sibling repositories queued, with a warning that it was
the most expensive open item: until it ran, 91 agent files across the fleet still
carried the `PS — Commits: a skill COMMITTER cuida disso` block telling agents
*not* to commit, pointing at a cycle that no longer runs.

It ran the same day. The block is now in **147** `CLAUDE.md`/`AGENTS.md` files —
50 repositories (each with its own bump, commit, push and Release) and 26
worktrees (no bump: the version belongs to the mainline, and repeating one number
across 20 branches manufactures exactly the duplicate the `pre-push` hook exists
to reject). No PS block survives outside the quarantine directory.

Two things the sweep found that a naive replacement would have missed, recorded
because the next fleet pass will meet them again:

- **The PS block had two heading variants** — the Portuguese original in 38 files
  and an English translation, `## PS — Commits: the COMMITTER skill handles them`,
  in the 6 SSHVTERM files. A pattern matching only the first would have left the
  false instruction standing in three repositories.
- **`_quarentena/2026-09-03/` is not inert.** Its copies are full clones pointing
  at the same production remotes as the live repositories — the SHVIA-WEB copy
  was three commits behind the live one — and several sit on a detached HEAD.
  Committing or pushing from there publishes stale state to a live remote. It was
  left out deliberately; 14 files there still carry the old block.

**The ADR-007 twins came with it.** Six repositories — `BLUE3-F1`,
`BLUE3-INTRANET-MOBILE`, `BLUE3-NDRIVE-SERVER`, `BLUE3-SITE-FRONT`,
`BLUE3-WCUP-2026` and `BRASILEIRAO_A_2026` — still used the older shape where
`AGENTS.md` was the real document and `CLAUDE.md` a summary of it (or, in
NDRIVE's case, the reverse, with `AGENTS.md` reduced to a pointer). They are one
document now, byte-identical below the H1, following the shape SHVIA-WEB set at
`2.110.166`.

Merging them was not concatenation. Three of the pairs **contradicted each other
about the commit convention**: `BLUE3-INTRANET-MOBILE` and `BLUE3-F1` had
`AGENTS.md` mandating Conventional Commits (`feat:`, `fix:`) while `CLAUDE.md`
mandated `X.Y.Z - description`, and Conventional Commits is what
[ADR-003](docs/decisions.md) forbids. Every such conflict was resolved toward the
fleet norm, and the same pass corrected the `Mensagem em português` lines that
[ADR-014](docs/decisions.md) had made false — they were sitting in the same file
as a `COMMIT-RULE` block saying English (US).

Every repository touched has its tag and Release: 57 checked, `version.md`
matching the published `Latest` in all of them.

## 1.5.0 - the agent commits again, and nothing is finished until it is committed

For a month the agents in this fleet did not commit. The COMMITTER skill existed
to take that work off them: from 30/07/2026 a `.committer.yml` marker was the
opt-in, a cron cycle read the changelog entry the agent had left behind, built
the `X.Y.Z - description` subject from it, committed and pushed. The rollout put
the marker in 43 repositories and a matching block into 42 `CLAUDE.md`/`AGENTS.md`
files, and that block said it plainly: *"commitar e pushar não é trabalho seu"*.

On 03/09/2026 the owner switched the skill off across the fleet — 35 markers
flipped to `enabled: false`, and the sweep in `~/x/GIT/run.sh` now reports
`no-op: kill-switch` for all 44 repositories it discovers.

**Switching off the automation did not unwrite the delegation.** That is the
defect this version closes. The instruction "do not commit" is still sitting in
42 agent files; the cycle that was supposed to follow it no longer runs. An agent
reading one of those files stops at a dirty working tree that nothing is
watching — a state strictly worse than before the skill existed, because before
it the agent at least knew the commit was its job.

**[ADR-016](docs/decisions.md)** puts it back, and puts back more than was taken.
The old rule was only *how* a commit is written; this one covers *who* writes it
and *when*:

- **The agent commits** — `git commit` and `git push` as the last step of the
  work, with no automation downstream.
- **A delivery is not delivered until it is committed.** No task is reported as
  finished while it sits uncommitted. "Done" means it is in `git log`.
- **One subject per commit.** When the description needs an "and" to be true, it
  is two commits.
- **A large delivery is split into blocks**, grouped by subject, sharing one
  version — because the history is the documentation of *how* the work was done.

The normative text is the new
[`versioning.md` §"Who commits, and when"](docs/versioning.md#who-commits-and-when).
Two passages there had gone stale on the same day and were corrected in this
pass: the "Who creates it" table still listed COMMITTER as an owner of Releases,
and `CHANGELOG.md`'s own header still called itself *"the handoff artefact
between whoever does the work and whoever commits it"* — there is no handoff any
more, the two are the same agent.

**How it reaches the fleet is the part that was designed rather than written.**
The rule ships as `templates/echo-blocks/COMMIT-RULE.md`, a delimited block in
the shape `RELEASES-RULE` already uses in 113 files, and `templates/echo-blocks/`
is new in this version for exactly that purpose. The reasoning is in the ADR: the
COMMITTER rollout is itself the proof that per-repo wording does not survive a
reversal — it put bespoke prose into 42 files, and when the decision behind it
was undone there was no mechanical way to find and replace it. A named,
delimited block can be regenerated in one pass.

**What is done here and what is not.** repodocs carries the block, the golden
rule, the release-gate line in `conventions.md` §4 and the skeleton, so every
repository created from now on is born with the rule. The 42 files in the
existing fleet still carry the false PS block; that pass is queued in
`.continue/README.md` with a warning that it is the most expensive open item,
because until it runs the fleet's agent instructions contradict this repository.

## 1.4.3 - correcting the activation claim in 1.4.2: the hooks are live here

The 1.4.2 entry said *"the hook is not active anywhere yet — no clone in the
fleet has `core.hooksPath` set"*. That was written from a sample of six
repositories and is false: the push that published 1.4.2 was itself checked by
the hook, which printed `pre-push: version 1.4.1 -> 1.4.2 — ok`.

Measured across all 92 clones under `~/x`: **exactly one has `core.hooksPath`
set — `repodocs` itself.** Only two carry `tools/git-hooks` on disk at all
(`repodocs` and `EOP`). So the defect was live in precisely the repository whose
`version.md` is a bare string and therefore passed the broken check anyway, and
latent in the 91 others.

The finding and the fix in 1.4.2 stand unchanged; only the reach claim was
wrong. Corrected in place there as well, because a measured number that is wrong
is the failure mode this repository exists to prevent — history is not
rewritten, so this entry records that the correction happened.

## 1.4.2 - the pre-push hook reads the first semver, like release.sh already did

`tools/git-hooks/pre-push` rejected any `version.md` that was not a bare `X.Y.Z`
string, and said so citing `docs/versioning.md` — the document that says the
opposite. [ADR-012](docs/decisions.md) replaced the bare-string requirement with
the first-semver rule precisely because a third of the fleet was measured to use
the markdown shape, and `tools/release.sh` has implemented that rule since it was
written (`first_semver()`, line 65). Two files, one rule, two readings; the hook
had the wrong one.

**What it would have cost.** Measured on
the fleet today: `shvia-workspace` (`**Versão atual:** \`0.27.17\``) and
`skill-dashproject` (`0.5.4`) both fail the old check and pass the new one, and
so does every BLUE3-ISP repository. Enabling the hooks as documented would have
refused every push from those repos, with an error message rendered unreadable
by `tr -d '[:space:]'` collapsing the whole markdown file into one string.

Fixed in the root hook **and** in `templates/skeleton/tools/git-hooks/pre-push`,
which is the copy every new repository inherits — the same defect was being
minted forward. Both the local read and the `origin/<default>` read now use
`grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1`, byte-for-byte the reading
`release.sh` does, so the duplicate-and-monotonicity checks keep working on both
file shapes.

Also corrected here, under the "stale in the same pass" rule: this file's own
preamble still described the commit format as *"versão - comentário em
português"*, which [ADR-014](docs/decisions.md) superseded on 03/09/2026.

## 1.4.1 - the release workflow fires on the default branch, whatever it is named

Caught by the final sweep of the rollout: 50 of 51 repos had `version.md` equal
to the `Latest` Release. The one that did not was `blue3-intranet-ntheme`, at
`0.1.3` with the Release stuck on `0.1.1`.

**Cause.** `release.yml` listed `branches: [master, main]`. That reads like "the
default branch" and is not: this repo works on `dev`, by written decision
recorded in its own `version.md`. The workflow had **zero runs** since being
installed — it was never going to fire.

**Fix.** The branch filter is gone. The job checks `github.ref_name` against
`github.event.repository.default_branch` instead, which is the same authority the
whole rule already rests on. Verified: the push landed on `dev`, the workflow ran
in 16s, and the Release appeared.

The two versions it had missed (`0.1.2`, `0.1.3`) were backfilled, and the badge
reconciliation moved `Latest` to `0.1.4` on its own — the self-healing behaviour
added in `1.2.3` doing its job unprompted.

**The other 50 repositories keep the older trigger for now.** It is functionally
correct for all of them (every one is on `master` or `main`), so a 50-commit
sweep to change a line that changes no behaviour was not worth the churn. What
this costs is written into [ADR-015](docs/decisions.md): moving a repository to a
non-standard branch is a written decision, and checking that its `release.yml` is
the current one is part of that decision.

## 1.4.0 - the default branch is `master`, never `main`

Census of the 51 fleet repositories, 03/09/2026: **43 on `master`, 7 on `main`,
1 on `dev`**. The seven are not a decision — they are repositories created after
GitHub changed its own default, inheriting whatever the button gave them.

### Why uniformity is the point

Git does not care. Every script, runbook, hook and workflow that wants "the
default branch" does: it either hardcodes one and is wrong for part of the
fleet, or resolves it at runtime and carries a fallback chain forever.
`tools/release.sh` does the latter today **because** the fleet is mixed. This
ADR is what lets those fallbacks be deleted later.

### It already broke something, in this rollout

`samirhvbr/samirhvbr` has GitHub's default at `master` and only `master` on the
remote — but a **stale local `origin/HEAD` still pointing at `origin/main`**. The
fleet sweep read it, derived `main`, pushed `HEAD:main` and was refused. The
failure reads like a permissions problem and is actually a branch name.

Fixed with `git remote set-head origin -a` — the step everyone skips when
renaming a branch, and the one that causes this exact class of failure.

### The rule

`master` is the default branch of every repository here. A repo created as `main`
is renamed with GitHub's own rename (it preserves open pull requests and
redirects old links), and every existing clone is repointed — including
`set-head`.

A different branch is allowed **when it is a written decision**:
`blue3-intranet-ntheme` works on `dev` and says so in its own `version.md`. A
repo sitting on `main` because that is what the button did is not a decision.

### Suggested, not swept

Renaming a default branch is outward-facing: it touches clone instructions, CI
configs that name the branch, and bookmarks to branch URLs. GitHub's rename
covers PRs and redirects; it does not fix a collaborator's clone or a workflow
file that hardcodes `main`. So the seven are **listed for the owner to
schedule**, not renamed on the strength of a convention:

`blue3-debian-custom-iso` · `blue3-ai-login` · `MIGRANDO-ZIMBRA-CARBONIO` ·
`shvia-bench` · `shvia-rota` · `shvia-site` · `shvia-workspace`

Written up in [ADR-015](docs/decisions.md), `docs/conventions.md` §7, the
`CLAUDE.md`/`AGENTS.md` twins and the skeleton.

## 1.3.1 - Agent doc: Releases rule and the English-only language rule

Marked echo of the single source at samirhvbr/repodocs. Two rules land here:

1. The `version.md` of the default branch ON GITHUB is what the GitHub Releases
   show, and a commit that bumps it is not finished until that version has a
   tag, a Release and the `Latest` badge — same push, not "later".
2. Everything in this repository is English (US): documents, commit messages,
   pull requests, issues, code comments. The only carve-out is end-user-facing
   product strings. History is not rewritten.

Delimited by a marker, so re-running replaces instead of duplicating.


## 1.3.0 - everything is English (US), commit messages included

The owner rejected the last language split, and the trigger was a commit this
very rollout had just written across the fleet:

> `1.0.1 - Regra de Releases no doc de agente: bump e Release sao um ato so`

> *"precisamos documentar a regra de que commits tambem, tudo em ingles"*
> *"todo commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*

### Why the split did not survive

ADR-005 put documents in English but kept commit messages in Portuguese,
reasoning that the commit convention was a separate per-repo rule. That reasoning
ignores where a commit message is actually read: `git log`, `git blame`, the diff
of a pull request, the body of a Release, and the changelog entry it was copied
from. It is exactly the surface the English rule exists for — the first thing a
collaborator or a tool that does not read Portuguese meets.

### The rule now

**Everything in a repository, and in GitHub's interface around it, is English
(US)** — documents, commit messages, PR titles and bodies, issues, code comments,
changelog entries, release notes.

**Exactly one carve-out remains:** end-user-facing strings — UI text,
transactional email, product copy. A Brazilian user does not read the repository.

That takes the carve-out list from three, to two after `LICENSE` fell in
[ADR-010](docs/decisions.md), to **one** here in
[ADR-014](docs/decisions.md).

### What was changed

`docs/conventions.md` §8, `docs/versioning.md` (format and examples),
`docs/README.md`, `README.md`, the `CLAUDE.md`/`AGENTS.md` twins, and the whole
`templates/skeleton/`. ADR-003's language clause is marked superseded rather than
edited away; ADR-005's carve-out list now points here.

### What enforces it, and what does not

`tools/git-hooks/commit-msg` checks the **shape** — `X.Y.Z - description`, no
Conventional Commits prefix, no vague one-word message — and its reject list
gained the English offenders (`cleanup`, `changes`, `tweak`, `stuff`,
`refactor`) next to the Portuguese ones already there.

It does **not** check the language, on purpose. Detecting language mechanically
is guesswork, and a guard that fires on a false positive is a guard that gets
bypassed with `--no-verify` — which disables every other guard with it. The
shape is mechanical; the language is the norm's job.

### History is not rewritten

Portuguese messages already in the fleet's history stay. `git log` will read
bilingual across the 03/09/2026 boundary, which is the same shape ADR-005
already accepted for documents, for the same reason.

## 1.2.4 - Regra de Releases no doc de agente: bump e Release sao um ato so

Eco marcado da norma unica em samirhvbr/repodocs (docs/versioning.md). O
`version.md` da branch padrao NO GITHUB e o que as Releases no GitHub mostram, e
um commit que bumpa o `version.md` nao esta terminado ate aquela versao ter tag,
Release e o badge `Latest`.

Bloco delimitado por marcador: rodar de novo substitui, nao duplica.


## 1.2.3 - o bump e a Release sao um ato so, e o badge Latest obedece ao version.md

Achado do dono, olhando o `sshvterm-desktop`: *"teve um bump para version.md
para 1.2.81 mas o Releases esta em 1.2.80"*.

### O que estava errado

A Release `1.2.81` **existia** — o workflow rodou e criou. O que estava errado
era so o **badge `Latest`**, parado na `1.2.80`. Varredura nos 51: tres repos
com o mesmo sintoma, e nos tres a Release existia. O pior era o `shvia-web`,
com `version.md` em `2.110.162` e badge em `2.16.38`.

### A causa foi minha

O backfill carimbava `--latest` na **ultima versao que aquela rodada conhecia**.
No `sshvterm-desktop` ele comecou lendo `1.2.80`, um push moveu o arquivo para
`1.2.81` no meio, e no fim ele empurrou o badge de volta para `1.2.80`. Correu
contra o proprio workflow — e ganhou a corrida errada.

### Duas correcoes no `release.sh`

1. **`--latest` so vai para a versao que o `version.md` nomeia**, nunca para "a
   ultima que esta rodada tocou".
2. Toda execucao termina **relendo o `version.md` do remoto e movendo o badge**
   se ele tiver derivado. Isso torna qualquer rodada auto-corretiva:

       release.sh: badge Latest movido de 1.2.80 para 1.2.81 (version.md manda)

Entao a pergunta *"este repo esta certo?"* virou um comando que tambem conserta:
`./tools/release.sh`.

### A regra que passou a estar escrita

**O bump e a Release sao um ato so.** Um commit que bumpa o `version.md` nao
esta terminado enquanto aquela versao nao tiver Release **e o badge**. Nao
"depois", nao "quando alguem lembrar" — no mesmo push. Esta em
`docs/versioning.md`, no gate de fechar versao do `docs/conventions.md`, nos
gemeos e no skeleton.

O badge nao e cosmetico: quem olha le como *"esta e a versao corrente"*, e um
badge numa Release velha afirma algo falso sobre o projeto.

### Um erro de operacao que vale registrar

Eu editei o `release.sh` **com ele rodando** no backfill do `shvia-web`. O bash
le o arquivo em pedacos, o deslocamento quebrou a sintaxe no meio da execucao
(`syntax error near unexpected token` na linha 226) e a rodada morreu em
`2.16.71` de 764. Retomada com uma **copia congelada** do script — o backfill e
idempotente, entao ela continuou de onde parou, mas o certo era congelar antes.

## 1.2.2 - o remoto e a autoridade: version.md do GitHub = Releases do GitHub

Correcao do dono, e ela apagou uma ambiguidade que eu tinha deixado em pe:

> *"no github o Releases tem que estar na mesma versao do version.md, e meio
> logico, esquece o local"*

O `release.sh` estava lendo o `version.md` da **arvore local**. Passa a ler do
**`origin/<branch padrao>`** e a taggear aquele commit, caindo para `HEAD` so
quando o ref remoto nao resolve — que e o caso do CI, onde o `HEAD` **e** o
commit pushado. Arquivo local divergente vira uma nota, nao uma Release
diferente.

### Por que isso nao era detalhe

Medido no mesmo dia: o `sshvterm-desktop` tinha `1.3.19` local contra `1.2.80`
no remoto (8 commits nao pushados), e o `shvia-web` tinha `2.110.154` local
contra `2.110.161`. Publicar da arvore local taggearia **commit que o GitHub nao
tem**. O guard anterior (recusar quando a arvore diverge do HEAD) tratava o
sintoma; a regra do dono elimina a pergunta.

### O que isso resolve de graca

O fluxo de PR passa a funcionar sem ninguem lembrar de nada: uma branch em
`1.3.25` **nao publica nada** enquanto e branch; no merge, o push do `version.md`
para a branch padrao dispara o workflow e a Release vira `1.3.25`. O merge e o
evento.

### Tambem nesta versao

- **`sshvterm-desktop`, o unico repo da frota com pipeline amarrado em tag.** As
  17 Releases dele eram de junho, tituladas `ShvTerm v0.5.41`, com **178
  instaladores e 10.184 downloads**. Os titulos foram para o padrao (so o
  numero); **nada foi apagado** e os binarios estao intactos. O `v` da tag ali
  **faz trabalho**: o `main.yml` dispara em `tags: ['v*']` — e por isso o
  proximo passo e o gatilho aceitar as duas formas, nao trocar de forma.
- **O `release.sh` deixou de duplicar Release.** Uma versao conta como publicada
  sob **qualquer um dos dois nomes**: criar uma `0.5.41` pura ao lado da
  `v0.5.41` que ja tem binario nao consertaria nome nenhum — duplicaria a versao
  e a copia sairia **sem os instaladores**. No `sshvterm-desktop` isso muda o
  backfill de 227 para **210 criadas e 17 puladas**.

## 1.2.1 - o censo completo derruba o numero que a 1.2.0 publicou

A `1.2.0` afirmou *"54 repositorios, zero Releases publicadas, e tres tags entre
todos eles"*. **Errado.** Aquele numero saiu de uma varredura parcial — a
caminhada local em `~/x` mais a org BLUE3-ISP — e **perdeu o SSHVTERM-DESKTOP
inteiro**.

### O numero real, do censo dos 52 repos com `version.md`

| | |
|---|---|
| Sem nenhuma Release publicada | **50 de 52** |
| Sem nenhuma tag de versao | **47 de 52** |
| Versoes distintas na frota | **~2.764** |
| EOP + SHVIA-WEB | **1.591 delas — 55% do total** |

E cinco repos **ja fazem isso**, todos com prefixo `v`: `SSHVTERM-DESKTOP` (22
tags e **17 Releases publicadas**, tituladas `ShvTerm v0.5.41`),
`brasileirao-a-2026` (17 tags), `blue3-wcup-2026` (3), `blue3-f1` (1), e o
`docsys_blue3` (19 tags, 18 Releases), que e do Rodrigo e esta fora desta frota.

### A consequencia que agora esta escrita

Mostrado o numero, o dono confirmou a decisao: **tag pura em todos, inclusive
nesses cinco**. A consequencia e real e fica dita de frente no
[ADR-011](docs/decisions.md): o SSHVTERM-DESKTOP vai ter `v0.5.41` com a Release
*"ShvTerm v0.5.41"* **convivendo** com uma `0.5.41` nova — a mesma versao
alcancavel por dois nomes. As tags velhas **nao sao apagadas**: apagar orfanaria
17 Releases que ja existem e que alguem pode ter linkado.

### Um defeito que o censo pegou no `release.sh`

O `--current` taggeava o HEAD com a versao lida da **arvore de trabalho**. Oito
repos da frota estao agora com o `version.md` bumpado e **nao commitado** — o
SHVIA-WORKSPACE esta 14 versoes a frente do ultimo commit. Nesses, o `--current`
teria criado uma tag apontando para um commit que nao contem aquela versao.

Agora ele recusa e explica, e diz que o `--backfill` e seguro ali (ele le o
historico, nao a arvore). Testado nos dois sentidos.

### Outros dois achados do censo, ainda abertos

- **SHVIA-WEB local esta 18 commits atras do origin** (local `2.110.154`, origin
  `2.110.161`). Backfill a partir do checkout velho perderia 8 versoes.
- **SHVIA-OLLAMA tem `version.md` nao rastreado pelo git** (`1.2.0`), enquanto a
  ultima versao commitada e `1.1.1`.

Ambos estao na fila em [.continue/README.md](.continue/README.md).

### Por que isto virou entrada propria em vez de conserto silencioso

O CHANGELOG nao e reescrito — e a regra da casa, e ela vale principalmente
quando o que esta escrito e o **erro**. A `1.2.0` fica como esta; esta entrada
diz o que estava errado e o ADR-011 ganhou o aviso apontando para ca. E a
terceira vez seguida que medir contrariou o que este repositorio tinha escrito.

## 1.2.0 - toda versao vira tag e Release, e a regra do version.md sai do papel

O quadro **Releases** do GitHub estava vazio em **todos os 54 repositorios** da
frota, e a causa nao era descuido: o GitHub nunca deduz versao de mensagem de
commit. Um repo com mil commits `2.110.161 - ...` continua dizendo *"No releases
published"*, e `git diff 2.110.160..2.110.161` falha porque **nenhum dos dois
nomes existe como ref**.

### O que foi medido antes de escrever qualquer regra

| Repo | commits | versoes distintas | tags | Releases |
|---|---|---|---|---|
| SHVIA-WEB | 1085 | 756 | 0 | 0 |
| EOP | 840 | 827 | 0 | 0 |
| SHVIA-DESKTOP | 1035 | 98 | 1 | 0 |
| BLUE3-INTRANET | 982 | 150 | 0 | 0 |
| SSHVTERM-WEB | 135 | 75 | 0 | 0 |

Tres tags em 54 repositorios, e zero Releases. Dois repos ja carregavam a divida
**por escrito** no proprio `version.md`: o `blue3-f1` diz *"Ao publicar, taggear
`v0.3.0`"* e o `brasileirao-a-2026` diz *"⚠️ Sem tag `v0.16.0` no git"*.

### A regra que este repositorio publicou errada

O `docs/versioning.md` e o ADR-002 afirmavam que o `version.md` e *"uma string
`X.Y.Z` pura e nada mais"*. **Falso para um terco da frota.** Nove repos do
BLUE3-ISP e o proprio skill-COMMITTER tem um `version.md` que e um documento
markdown inteiro, abrindo com `**Versao atual:** \`0.17.1\``; o
`blue3-intranet-mobile` tem duas linhas (`2.1.9` e `api_min: 0.1.0`).

Esses repos ja documentavam a regra de verdade — *"extrai o primeiro numero
semver encontrado aqui"* — e o `config/app.php` deles ja implementava com
`preg_match('/\d+\.\d+\.\d+/')`. **A versao e o primeiro semver do arquivo**
([ADR-012](docs/decisions.md)), e o ADR-002 fica emendado, nao apagado.

E a segunda vez que uma norma daqui foi contrariada pela frota — a primeira foi o
`LICENSE` bilingue custando o selo MIT (`1.0.1`). As duas apareceram medindo, nao
relendo.

### O que passou a existir

- **`tools/release.sh`** — a implementacao unica: `--current`, `--backfill`,
  `--dry-run`. Idempotente e retomavel por construcao (pula o que ja existe),
  com throttle e parada limpa quando o orcamento de API baixa.
- **`.github/workflows/release.yml`** — dispara a cada push que toca o
  `version.md` e **chama o script**, em vez de reimplementar as regras: duas
  copias de uma regra e como uma regra passa a ter duas versoes, uma errada.
- **ADR-011** (tag e Release por versao), **ADR-012** (primeiro semver),
  **ADR-013** (workflow de release nao e workflow de CI — o ADR-009 fica
  estreitado para proibir so build/teste, com o motivo: CI vermelha em repo de
  documentacao ensina a ignorar CI, e este workflow e silencioso no caso normal).

### A tag nao leva `v`

Decisao do dono. Diverge das tres tags que a frota ja tem (`v0.15.0` e uma na
SHVIA-DESKTOP), que **ficam como historico**; o que sera corrigido sao os dois
`version.md` cujo texto ainda manda usar `v` — documento contradizendo o artefato
e o defeito, nao a tag velha.

### Medido neste repo

Backfill rodado: `1.0.0` → `b5bc824`, `1.0.1` → `e8131fe`, `1.1.0` → `654c999`,
com as notas vindas da secao real do CHANGELOG (a extracao foi corrigida para
parar so num heading do mesmo nivel ou acima — na primeira versao ela cortava a
`1.0.0` no primeiro `###` e perdia 78 das 83 linhas). Re-execucao: zero criadas,
tres puladas. E `git diff 1.0.1..1.1.0` finalmente responde — 16 arquivos.

### O que falta

O rollout nos outros 53 repositorios, com o backfill completo (~2.000-3.000
Releases) sob dry-run lido repo a repo, e o passo equivalente no
**skill-COMMITTER**. Esta na fila em [.continue/README.md](.continue/README.md).

## 1.1.0 - nada bilingue: o LICENSE passa a ser o MIT em ingles puro

Resposta do dono a medicao da `1.0.1`: *"nao, nada bilingue, so ingles, license
e etc so ingles"*. A pergunta que estava na fila saiu respondida.

**O que mudou.** O `LICENSE` deixa de ser PT-depois-EN e passa a ser o texto MIT
em ingles, **byte-identico ao canonico** — o mesmo do `skill-LOOP`, que era o
controle da medicao e que o GitHub detecta como `MIT License`. O
`templates/skeleton/LICENSE` acompanha, com `<YEAR>`/`<OWNER>`.

**O que isso custa, dito de frente.** O `LICENSE` deste repo **nao e mais
byte-identico aos catorze da frota** — ele e byte-identico ao MIT canonico. A
divergencia esta na direcao certa e fecha substituindo os outros, nao revertendo
aqui. Entrou na fila junto com o retrofit da norma.

**A regra de idioma encolheu de tres excecoes para duas.** Ficam em portugues
so a **mensagem de commit** e as **strings voltadas ao usuario final**. O
`LICENSE` saiu da lista, e o par `README.md`/`README_br.md` fica explicitamente
recusado pelo mesmo motivo que uma norma copiada: dois documentos dizendo a
mesma coisa divergem, e um deles fica errado em silencio — o par do
BLUE3-INTRANET esta em 374 linhas contra 259.

**Onde ficou registrado.** [ADR-010](docs/decisions.md) e a decisao nova;
supera a clausula bilingue do ADR-006 (que mantem o resto: nome sem extensao,
MIT, titular, e a regra de o NOTICE nunca contradizer o LICENSE) e revisa a
lista de excecoes do ADR-005. A norma em `docs/conventions.md` §8, os gemeos
`CLAUDE.md`/`AGENTS.md`, os dois `README.md`, os dois `versioning.md` e o
`docs/README.md` foram corrigidos na mesma passada — documento que envelhece em
silencio e pior que documento ausente.

**A fila perdeu uma linha.** O item *"vale o LICENSE bilingue?"* foi **apagado**
de `.continue/README.md`, nao marcado como feito: item concluido sai da fila, e
o registro permanente e este arquivo. Bump **Y** porque houve ADR novo.

## 1.0.1 - o LICENSE bilingue custa o selo MIT do GitHub, medido

Um push é o único jeito de medir o que o GitHub faz com um `LICENSE`, e a
medição contradisse a expectativa.

**O que foi medido.** Depois do push da `1.0.0`, `gh repo view` devolveu
`licenseInfo: Other` — não `MIT License`. O mesmo vale para SHVIA-WEB,
SHVIA-SITE e BLUE3-AI-LOGIN, os três que carregam o mesmo texto bilíngue.
Controle: `skill-LOOP`, que carrega o MIT puro em inglês, é detectado como
`MIT License`.

**Por que.** O detector do GitHub compara o arquivo inteiro com um template de
licença. A metade em português derruba a similaridade abaixo do limiar dele. A
licença **é** MIT nos dois casos — o que se perde é o selo na barra lateral e a
detectabilidade via API.

**O que mudou aqui.** Nada no LICENSE: a escolha do bilíngue foi deliberada e
segue valendo. O que mudou é que o custo dela está medido em vez de suposto —
[ADR-006](docs/decisions.md) ganhou a seção do custo, e a decisão de manter ou
inverter entrou na fila em [.continue/README.md §3](.continue/README.md) como
chamada do dono. A inversão, se vier, espelha o par `README.md`/`README_br.md`
que a frota já usa.

**Também confirmado no mesmo push:** o `SECURITY.md` na raiz funcionou — o
`securityPolicyUrl` do repositório passou a existir.

## 1.0.0 - estrutura inicial de documentação do padrão da frota

The first real content of `repodocs`, which until now was one commit and an
11-byte `README.md`. GitHub's own description of it — *"Documentation for new
repository"* — already said what it was for; this release makes it true.

### What this settles

The standard existed, but only as a pattern to be inferred by opening sixteen
repositories and noticing what they had in common. The measurement:

| Convention | Evidence across the fleet |
|---|---|
| `LICENSE`, no extension | 41 files against **1** `LICENSE.md` |
| `NOTICE`, no extension | 11 files, zero `NOTICE.md` |
| `version.md`, lowercase, bare `X.Y.Z` | 63 files against 1 `VERSION` |
| MIT bilingual PT/EN, `Copyright (c) 2026 Samir Hanna Verza` | byte-identical in 14 repositories |
| Commit `versão - comentário em português` | normative in EOP, SHVIA-DESKTOP, SHVIA-SITE, SHVIA-WEB, BLUE3-INTRANET |
| `CLAUDE.md` + `AGENTS.md` identical below the H1 | EOP and SHVIA-DESKTOP (BLUE3-INTRANET symlinks; SHVIA-WEB diverged on purpose) |

An inferred standard is a standard that drifts. It is now written once, in
English, at [docs/conventions.md](docs/conventions.md).

### The move that mattered

`BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` (157 lines, written 29/08/2026)
already declared itself *"fonte única, vale para todos os repos da frota"* — and
its own §7 admitted the problem: the source of a fleet-wide norm was a path
inside one product repository. **That is the exact failure the document was
written to prevent**, applied to itself: a rule that lives inside one repo is
invisible to whoever opens another.

It moved here, translated, extended with what it lacked (the root-file standard,
the status vocabulary, the language rule and its carve-outs) — [ADR-001](docs/decisions.md).
The INTRANET copy has **not** been touched yet, so two copies exist and this one
is the source; retrofitting the pointer is a separate, explicit pass.

### Two contradictions settled rather than copied

Both were found while measuring, and both were live:

- **`SHVIA-WEB`** — its `LICENSE` says MIT under `Copyright (c) 2026 Samir Hanna
  Verza`, while its `NOTICE` says *"Copyright (c) Blue3. Proprietary software;
  see LICENSE."* Those cannot both be true. This repository's `NOTICE` agrees
  with its `LICENSE`, and [ADR-006](docs/decisions.md) makes that a rule.
- **`BLUE3-INTRANET`** — its `README.md` states *"the old `version.md` was
  removed in favour of this env var"* while `version.md` is still present and
  its own `CLAUDE.md` calls it the source of truth with the env var as fallback.
  [ADR-002](docs/decisions.md) makes `version.md` the sole authority and forbids
  a document from claiming otherwise. Two documents disagreeing about one number
  is how a wrong deploy gets signed off.

### What was created

- **Root:** `README.md` (rewritten), `version.md` (`1.0.0`), the
  `CLAUDE.md`/`AGENTS.md` twins, `SECURITY.md`, this file, `LICENSE` (copied
  byte-for-byte from the fleet's), `NOTICE`, `.gitignore`.
- **`docs/`:** `conventions.md` (the norm), `versioning.md`, `decisions.md`
  (ADR-001…009), `security.md` (English successor to `SECURITY_GUIDELINES.md`
  v1.1), `runbook.md`, `README.md` (index).
- **`.claude/`:** the fleet Opus profile with a 17-rule deny-list, and a
  `README.md` explaining why the deny-list beats the allow-list.
- **`.continue/`:** the queue, with the `README.md` that §2 of the norm makes
  mandatory.
- **`tools/git-hooks/`:** `commit-msg` and `pre-push`, on the EOP topology.
- **`templates/skeleton/`:** the placeholder copy of the whole set, so a new
  repository is `cp -r` plus one substitution pass.
- **`.github/`:** `CODEOWNERS` and `dependabot.yml`. Deliberately no workflow —
  [ADR-009](docs/decisions.md): a red CI on a documentation repository teaches
  people to ignore CI.

### Measured

The hooks were exercised in both directions before shipping: `feat: teste`
rejected, `1.0.0 - <comentário>` accepted, a duplicate version against
`origin/master` rejected, `REPODOCS_NO_HOOK=1` bypassing both, and an
unreachable remote degrading to a warning rather than a refusal. `LICENSE` is
byte-identical to `SHVIA-WEB/LICENSE`; the twins diff clean below the H1.

### What is left

The queue is [.continue/README.md](.continue/README.md). The open item is not
work in this repository — it is the retrofit pass into the sibling repositories,
which is the owner's call to schedule.
