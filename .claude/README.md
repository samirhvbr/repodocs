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
| `settings.json` | The **active** profile, versioned. Today: **nothing that chooses the model**, `effortLevel: high`, `defaultMode: plan`, a 5-rule deny-list, an 8-rule ask-list and a 17-entry allow-list. |
| `settings.local.json` | Machine-local override, **gitignored** — it may hold paths and tokens that belong to one machine. Never commit it. |

## Why this file does not choose the model

The model is the user's choice, made with `/model`, and a subagent inherits it.
So this file carries no `model` and no `fallbackModel`, and its `env` carries none
of the variables that steer one — `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`
and its siblings, `CLAUDE_CODE_SUBAGENT_MODEL`
([ADR-027](../docs/decisions.md#adr-027--the-model-is-the-users-choice-and-nothing-in-a-repository-makes-it)).

Two measurements on 24/09/2026 got it here. A pin in this file cannot win:
server-managed settings — cached in `<config_dir>/remote-settings.json` and
re-fetched at startup — outrank every local file, and a local edit to that cache
is reverted on the next fetch. And every pin the fleet carried outlived the model
it named. `opus[1m]` reads as a window choice and behaves as a version pin,
because the 1M variant existed only for the previous Opus
([ADR-026](../docs/decisions.md#adr-026--a-repository-does-not-pin-the-model-and-a-window-suffix-is-a-version-pin)).
`CLAUDE_CODE_SUBAGENT_MODEL=opus`, kept so that subagents would follow the newest
Opus, resolved through the same pinned alias: with the session on Opus 5.5, a
subagent and a workflow agent both reported `claude-opus-5`.

Where the choice does live: in the user's own settings, which `/model` writes,
and — above everything — in the organization's managed settings, which only an
owner edits and which apply to every member.

## Why `defaultMode: plan`

This repository *is* the norm. A change here propagates to every repo that
copies the skeleton, so the cost of a wrong edit is not one file — it is every
future repo that inherits it. Planning first is cheap insurance against that.
Repos created from the skeleton are free to choose `acceptEdits`; the skeleton
ships `plan` because that is the safe default to start from, not because every
project must keep it.

## The deny-list beats the allow-list — always

No allow-list entry can re-open a denied rule — that mechanism is unchanged.
What is denied changed on 24/09/2026, by the owner's decision
([ADR-028](../docs/decisions.md#adr-028--the-owners-permission-lists-five-commands-ask-seven-rules-leave-deny)):

- **Denied:** key reads by path — `*.pem`, `*.key`, `*.p8`, `*.p12`, `*.pfx`.
- **Ask for confirmation:** `sudo`, `rm -rf`, `curl`/`wget` piped into a shell,
  `gh repo edit`, `gh repo delete`.
- **In no list:** `git push --force` / `-f`, `git reset --hard`, `git clean -fd`
  and reading `.env`. A force-push and a `.env` read match `Bash(git push:*)` and
  `Read` in the allow-list and run without a prompt; `reset --hard` and
  `clean -fd` fall to the default prompt. Not rewriting published history is a
  rule of conduct here, not a block.

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
