# <PROJECT_NAME> — Instructions for Claude Code

<!--
  The content below the H1 is duplicated between CLAUDE.md (read by Claude
  Code) and AGENTS.md (read by other tooling, agents.md standard) — keep the
  two byte-identical below the H1. If you edit one, edit the other.
-->

> **Read in this order:** [.continue/README.md](.continue/README.md) (the queue —
> where we stopped, **always first**) · [docs/versioning.md](docs/versioning.md)
> (how a version and a commit are written) ·
> [docs/decisions.md](docs/decisions.md) (ADRs — do not re-litigate a decided
> direction, link the ADR) · [docs/security.md](docs/security.md) (normative;
> wins any conflict).
>
> **The fleet documentation norm is not in this repository.** It lives once, at
> [samirhvbr/repodocs `docs/conventions.md`](https://github.com/samirhvbr/repodocs/blob/master/docs/conventions.md).
> Read it there; do not copy it here.

---

## 🔄 Before you start: `git pull`

**ALWAYS** check for remote updates before writing or changing anything in this
repository:

```bash
git pull
```

Working on a stale base creates conflicts. Pull first, always. To inspect
without merging: `git fetch && git status`.

**Fresh clone — enable the hooks ONCE:**

```bash
git config core.hooksPath tools/git-hooks
```

Two hooks then run, and each exists because the other cannot reach its moment:

| Hook | What it checks | Why there |
|---|---|---|
| `commit-msg` | The subject is `X.Y.Z - comentário em português`; no Conventional Commits prefix, no vague comment | It is the only moment the message exists and the commit does not |
| `pre-push` | `version.md` against the remote default branch — duplicate and monotonicity | It is the only hook that sees the **remote**, and `commit-msg` provably does not run during a rebase, which is how duplicate versions get born |

⚠️ **`pre-push` runs no suite, and that is a choice:** a push that waits four
minutes becomes `--no-verify` the following week, and then the control is dead.
**With no reachable remote it degrades with a warning, never a refusal.** Escape
hatch declared in both, named by `HOOK_ESCAPE_VAR` at the top of each hook —
rename it to `<ENV_PREFIX>_NO_HOOK`.

---

## What this project is

**<PROJECT_NAME>** — <PROJECT_DESCRIPTION>

<!-- Replace the block below with what an agent actually needs: the stack, where
     the entry points are, what runs locally, and what must never be touched. -->

- **Stack:** _to be filled in._
- **Runs locally with:** _to be filled in._
- **Never touch:** _to be filled in._

---

## Golden rules

1. **`.continue/` is the queue · `docs/` is the record · `CHANGELOG.md` is the
   history.** A document moves from queue to record the moment it describes
   something that already exists. A finished item **leaves** the queue.
2. **If a queue item needs half a page, it is in the wrong place.** Write it in
   `docs/` and leave one line and a pointer.
3. **In a contradiction between the queue and a document, the document wins.**
4. **Every prescriptive document declares its status** on the first lines:
   `ACTIVE` · `HISTORICAL` · `PROPOSED` · `DEPRECATED` · `NOT ADOPTED`. One
   with no declaration is read as `ACTIVE`, which is exactly the failure mode.
5. **A document made stale by a change is fixed in the same pass.** A document
   that ages in silence is worse than a missing one, because it has the
   authority of being written down.
6. **`CLAUDE.md` and `AGENTS.md` are byte-identical below the H1.** Edit one,
   edit the other.
7. **Everything is versioned; the only exception is a secret.** `.claude/` and
   `.continue/` are tracked on purpose. A new `.gitignore` exception beyond
   secrets requires an ADR, never a silent line.
8. **Granting the agent a permission is the owner's act** — written into
   `.claude/settings.json` with its reason and how to revert it, never applied
   silently and never left as a promise in prose.
9. **A new decision becomes an ADR** in `docs/decisions.md`, in the same pass.

---

## Language

**English** for every document and code comment. Nothing is rewritten merely
because of the rule: an old Portuguese document stays Portuguese until it is
touched again.

**Three carve-outs stay Portuguese** — do not "fix" them:

- **Commit messages** — `versão - comentário em português`.
- **End-user-facing strings** — UI text, transactional email, product copy. That
  is product i18n for a Brazilian audience, not technical documentation.
- **`LICENSE`** — bilingual PT/EN, byte-identical across the fleet.

Code identifiers are English.

---

## Version and commits (mandatory)

Format: `versão - comentário em português`. The version comes from
[version.md](version.md), **bumped in the same commit**:

<!-- The X/Y/Z slots and the discipline are the fleet convention. What counts as
     a Z is per-project — replace these with this project's real triggers. -->

- **Z** — _e.g. a new screen, a new table, a layout change, a wording fix._
- **Y** — _e.g. a new main service, an API redesign, a compatibility break._
- **X** — reserved; a stable release, by hand.

Forbidden: `feat:` / `fix:` / `chore:` prefixes and vague messages ("ajuste",
"update", "wip"). Several commits may share one version — group by subject, bump
in the first, repeat the number in the rest.

**Write the `CHANGELOG.md` entry first: its `## X.Y.Z - description` heading
*is* the commit subject.** Bodies are narrative — what changed, why, and what it
measured — not bullet lists.

Full rules: [docs/versioning.md](docs/versioning.md).

---

## Before closing a version

- [ ] What changed is in `CHANGELOG.md`, with the **why**, not just the what.
- [ ] A new or changed document is in `docs/` — not in the queue, not in the
      commit body.
- [ ] A finished item **left** `.continue/`.
- [ ] A document made stale by this change was corrected in the same pass.
- [ ] `version.md` bumped, in this commit.
- [ ] The twins still match: `diff <(tail -n +2 CLAUDE.md) <(tail -n +2 AGENTS.md)`.
