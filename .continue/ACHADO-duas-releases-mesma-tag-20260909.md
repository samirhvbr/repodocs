# Finding — one tag can carry two Releases, and the two publishers do not see each other

> **Measured on 09/09/2026, and produced by following the documented instruction.** This
> is a finding, not a fix. `tools/release.sh` and `.github/workflows/release.yml` ship to
> the whole fleet, so the change is a spec, not a patch made in passing.

## What happened

Version `1.14.2` was pushed and `./tools/release.sh` was run right after, which is what
the `RELEASES-RULE` block says to do. The script reported exactly what it should:

```
mode:    current
already: 39 Release(s) published

  1.14.2         7eb8e8b  published

created/would-create: 1   skipped: 0   failed: 0
```

The repository ended with **two Releases on the tag `1.14.2`**:

```
$ gh api "repos/samirhvbr/repodocs/releases?per_page=5" \
    --jq '.[] | "id=\(.id) tag=\(.tag_name) created=\(.created_at)"'
id=385845771 tag=1.14.2 draft=false created=2026-09-09T21:04:37Z
id=385845772 tag=1.14.2 draft=false created=2026-09-09T21:04:37Z   ← Latest
id=385818604 tag=1.14.1 draft=false created=2026-09-09T20:19:26Z
```

Same tag, same second, two ids. `1.14.1` and every version before it have exactly one.

## Why it happened

Two publishers run the same script and neither is aware of the other:

| Publisher | Trigger | What it calls |
|---|---|---|
| `.github/workflows/release.yml` | **every push** (no branch filter, by written decision) | `tools/release.sh` |
| the operator or an agent | by hand, as `RELEASES-RULE` instructs | `tools/release.sh` |

`release.sh` decides by asking whether a Release for the version already exists. In a race
**both ask before either answers** — the check and the create are not one operation, and
the GitHub API does not refuse a second Release on an existing tag. The tag is unique; the
Release is not.

🔴 **The gap is the width of one push.** Pushing and then running the script by hand puts
both publishers inside the same few seconds by construction. That is not an unlucky
schedule — it is the documented sequence.

## The sentence that has to change

The `RELEASES-RULE` echo block, in every repository of the fleet, says:

> *"It is **idempotent and self-healing**: it publishes whatever is missing and moves a
> drifted badge back. **Running it is always safe**, so it is both the check and the fix."*

Idempotent it is, on its own. **Concurrency-safe it is not**, and "always safe" is the
half of the sentence that this measurement contradicts. The sentence is what made running
it right after a push look like diligence.

⚠️ This is the same shape as everything else measured this week, one level up: an
instrument that reports a property it does not have **under a condition nobody tested**.
`release.sh` was tested alone; it was never tested beside itself.

## What it costs, honestly

Small, and worth stating so the spec is not over-scoped. The `Latest` badge lands on one
of the two, the tag resolves, and the changelog is unaffected. What breaks is **counting**:
`already: 39 Release(s) published` and anything else that reads Releases as one-per-version
starts drifting, and it drifts silently — which is the part that matters, because
`release.sh` is also *the check*.

## The state right now

**The duplicate has NOT been removed.** Deleting a published Release is outward-facing and
is the owner's call, not a cleanup to make in passing. Whichever is kept, `Latest` is
already on `385845772`, so removing the other changes nothing visible:

```bash
gh api -X DELETE repos/samirhvbr/repodocs/releases/385845771
```

## The decision, taken on the evidence

**Change the instruction, not the code.** The control below is what chose it: the workflow
publishes correctly on its own, so nothing in `release.sh` is broken and nothing in it needs
a lock. What is broken is a sentence telling the operator to run a second publisher inside
the same seconds.

Two alternatives were considered and are recorded so nobody re-opens them without new
evidence:

| Shape | Why not |
|---|---|
| **Re-check after creating** — `release.sh` lists Releases for the tag right after publishing and deletes its own duplicate | Code, in nine repositories, to fix a race that stops existing when the instruction changes. And it narrows the window without closing it: two truly simultaneous creates still pass |
| **One publisher** — retire the manual path | Correct destination, wrong order. The manual path exists because the workflow is not in all nine yet; `fleet.sh check` reports `9× release.sh differs` and `9× hooks not enabled` today. It closes after the rollout, not before |

### What the block says today, and what it has to say

The `RELEASES-RULE` echo block ships this in all nine repositories:

```markdown
- `.github/workflows/release.yml` does it on any push that touches `version.md`.
- `./tools/release.sh` does it by hand. It is **idempotent and self-healing**:
  it publishes whatever is missing and moves a drifted badge back. Running it is
  always safe, so it is both the check and the fix.
```

🔴 **`Running it is always safe` is the false half**, and it is false in exactly the
situation the surrounding text puts the reader in. The replacement:

```markdown
- `.github/workflows/release.yml` does it on any push that touches `version.md`,
  and on the normal path it is the **only** publisher you need. Push, and it
  publishes.
- `./tools/release.sh` is the **repair**, not the routine: run it when the
  workflow is absent or has failed, or to backfill. On its own it is idempotent —
  it publishes whatever is missing and moves a drifted badge back.
- 🔴 **Do not run it right after a push.** Both publishers call the same script and
  both decide by asking whether the Release already exists, so within the seconds
  after a push **both ask before either answers** — and the GitHub API does not
  refuse a second Release on an existing tag. Measured 09/09/2026 in `repodocs`:
  `1.14.2` ended with **two** Releases on one tag; `1.14.3` and `1.14.4`, pushed
  without the manual run, ended with **one** each.
```

**Not applied yet.** It is one edit in `templates/echo-blocks/RELEASES-RULE.md` and then
`fleet.sh echo --apply` across the fleet — which is a rollout, and rollouts are sequenced in
[`REPODOCS-CARIMBO-20260909.md`](REPODOCS-CARIMBO-20260909.md), not done in passing.

## The control, and its result

`1.14.3` was pushed and `tools/release.sh` was **not** run by hand. Measured afterwards:

```
$ gh api "repos/samirhvbr/repodocs/releases?per_page=10" \
    --jq '[.[] | select(.tag_name=="1.14.3")] | length'
1
```

**One Release**, published by the workflow alone. So the workflow covers the normal path on
its own, and the duplicate on `1.14.2` came from the second publisher — not from the
workflow misbehaving.

That makes the cheapest of the three shapes the one with evidence behind it: **change the
instruction, not the code.** `RELEASES-RULE` telling the operator to push and let the
workflow do it — running the script by hand only when the workflow is absent or has failed
— removes the race without touching `release.sh`. The *"running it is always safe"* sentence
has to go regardless of which shape is chosen.
