# Claude Code profile — repodocs

> **Status:** `ACTIVE`

`.claude/` in this repository follows the standard of the samirhvbr/Blue3
fleet: a **model profile** plus a **permission posture**, both versioned. There
is no application here, no database and no secret — repodocs holds
documentation, two git hooks and the [`templates/skeleton/`](../templates/skeleton/)
a new repository copies out.

Conduct rules for the agent are in [CLAUDE.md](../CLAUDE.md); the norm it
enforces is [docs/conventions.md](../docs/conventions.md).

## Files

| File | Role |
|------|------|
| `settings.json` | The **active** profile, versioned. Today: `opus[1m]`, `effortLevel: high`, `defaultMode: plan`, a 17-rule deny-list and a 13-entry allow-list. |
| `settings.local.json` | Machine-local override, **gitignored** — it may hold paths and tokens that belong to one machine. Never commit it. |

## Why `defaultMode: plan`

This repository *is* the norm. A change here propagates to every repo that
copies the skeleton, so the cost of a wrong edit is not one file — it is every
future repo that inherits it. Planning first is cheap insurance against that.
Repos created from the skeleton are free to choose `acceptEdits`; the skeleton
ships `plan` because that is the safe default to start from, not because every
project must keep it.

## The deny-list beats the allow-list — always

`Bash(git push:*)` is allowed, and `git push --force` / `-f` is still blocked.
That asymmetry is the point: pushing is routine, rewriting published history is
not, and no allow-list entry can re-open a denied one. The same holds for
`git reset --hard` and `git clean -fd`.

Secret reads are denied by path (`.env`, `*.pem`, `*.key`, `*.p8`, `*.p12`,
`*.pfx`) even though this repo has no such file. The rule travels with the
skeleton, where the files *will* exist — a guard added after the first secret
lands is a guard added too late.

## Granting a new permission is the owner's act

When a permission needs to exist, it is **written into `settings.json`
together with its reason and how to revert it** — never applied silently, and
never left as a promise in prose.

That last clause is not style. In a sibling repo the agent guide claimed
`git pull` was "pre-authorised (allow)" while no such rule existed in any
settings file; the norm and the artefact disagreed for weeks. A norm that does
not match the artefact is a defect. If you read a permission claim here, it
should be verifiable in the JSON next door — and if it is not, fix the JSON or
fix the claim.
