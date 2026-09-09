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

## A lead, not a decision

- **Re-check after creating, not only before.** `release.sh` could list Releases for the
  tag immediately after publishing and delete its own duplicate if it finds two. It is
  narrow and it closes the measured window; it does not close a true simultaneous create.
- **One publisher, not two.** The workflow exists because *"this fires no matter who
  pushed"*, which is a real reason. The manual path exists because the workflow is not
  everywhere yet. Retiring the manual path is only possible once `fleet.sh check` says the
  workflow is present in all nine — and that is a different item.
- **Or make the instruction the guard:** `RELEASES-RULE` says to run the script after
  pushing. Saying instead *"push, then let the workflow do it; run the script by hand only
  when the workflow is absent or failed"* removes the race without any code — and the
  sentence about "always safe" has to go either way.

> **Verification for whichever shape is chosen:** push a version bump and do **not** run
> the script. One Release for that tag means the workflow alone covers the normal path,
> and the manual run is only ever a repair. That control was run for `1.14.3` and is
> recorded in the changelog entry for it.
