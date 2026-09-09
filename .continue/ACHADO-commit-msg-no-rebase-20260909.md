# Finding — `commit-msg` is not invoked on `rebase --continue`

> **Measured on 09/09/2026.** This is a finding, not a fix. The change belongs to the
> template in `tools/git-hooks/` and therefore to all nine repositories of the fleet, so
> it needs a spec of its own rather than a patch made in passing.

## What happened

While renumbering a version collision in `SHVIA-DESKTOP` (two fronts forked from `1.4.30`
and both stamped `1.4.31`), a commit landed with the subject saying `1.4.33` while
`version.md` said `1.4.34`. **The hook did not stop it.** It was caught by re-reading
`git log`, not by the guard — and the path where it slipped is the one a person is on
precisely when they are renumbering.

## The measurement

A throwaway repository with the fleet's own `commit-msg` (copied from
`tools/git-hooks/`), plus one log line inserted **before every early exit** — that line
is what separates *"git never called it"* from *"the hook ran and returned"*. Positive
control verified first: a normal commit whose subject does not match `version.md` is
refused.

| path | hook invoked? | blocks? | measured as |
|---|---|---|---|
| `git commit` | ✅ | ✅ | subject `7.7.7` against `version.md=1.0.9` → refused |
| `git commit --amend` | ✅ | ✅ | amend to `8.8.8` with `version.md=1.0.6` → original subject survives |
| `cherry-pick --continue` | ✅ | ✅ | conflict resolved, `version.md=1.0.3`, inherited subject `1.0.1` → refused, HEAD did not move |
| `rebase -i` (reword) | ✅ | ✅ | log records the call; refuses with *"subject says 1.0.1, version.md says 1.0.4"* |
| 🔴 **`rebase --continue`** | ❌ **never called** | ❌ | log **empty**; the commit landed with subject `1.0.1` and `version.md=1.0.4` |
| `merge --continue` | ✅ called | ❌ **exits early** | log records the call; commit lands as `Merge branch 'm1' into m2` |

## The two failures have different causes, and only one is a defect

- **`rebase --continue` — git does not invoke the hook.** Not a single log line. Note
  how narrow this is: `rebase -i` with `reword` invokes it normally, so the gap is the
  `--continue` step specifically, not rebase as a whole.
- **`merge --continue` — the hook is called and exits by design.** `commit-msg:29` tests
  for `MERGE_HEAD` and exits 0 with *"merge commit — subject not checked"*, and the
  reason is written at line 23: a merge's versions live in the commits being merged.
  **This is a declared exemption. Do not "fix" it** — that is the row most likely to be
  mistaken for the bug.

## Why it matters beyond the repository that found it

**`SHVIA-WEB` runs its whole merge queue over rebase.** Its `CLAUDE.md` records 26 PRs
opened in a single day and `master` moving 12 versions during one session; every one of
those passes through `rebase --continue`. The guard that exists to keep the subject and
`version.md` agreeing is absent at exactly the step that rewrites both.

That repository stamps at merge (`scripts/versao-no-merge.sh`), which narrows the window
but does not close it: the script writes the two files and commits, and anything that
resolves a conflict by hand on the way still lands unchecked.

## A lead, not a decision

`post-rewrite` **does not exist** in `tools/git-hooks/` today (measured: the template
ships `commit-msg` and `pre-push`, nothing else). Git calls it after `rebase` and
`commit --amend` with the list of rewritten commits, which makes it the shape that fits
what is missing here.

⚠️ It is a different shape of guard, and the spec has to say so rather than assume:
`post-rewrite` runs **after** the rewrite, so it can report but cannot refuse. A guard
that reports is not the same promise as one that blocks, and calling it equivalent would
be the "it looks covered" failure this house keeps measuring.
