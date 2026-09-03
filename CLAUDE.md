# repodocs — Instructions for Claude Code

<!--
  The content below the H1 is duplicated between CLAUDE.md (read by Claude
  Code) and AGENTS.md (read by other tooling, agents.md standard) — keep the
  two byte-identical below the H1. If you edit one, edit the other. (ADR-007)
-->

> **Read in this order:** [.continue/README.md](.continue/README.md) (the queue —
> where we stopped, **always first**) · [docs/conventions.md](docs/conventions.md)
> (the norm this repository exists to hold) ·
> [docs/versioning.md](docs/versioning.md) (how a version and a commit are
> written) · [docs/decisions.md](docs/decisions.md) (ADRs 001–009 — do not
> re-litigate a decided direction, link the ADR) ·
> [docs/security.md](docs/security.md) (normative; wins any conflict).

---

## 🔄 Before you start: `git pull`

**ALWAYS** check for remote updates before writing or changing anything in this
repository:

```bash
git pull          # pre-authorised (allow)
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
| `commit-msg` | The subject is `X.Y.Z - description in English`; no Conventional Commits prefix, no vague comment | It is the only moment the message exists and the commit does not |
| `pre-push` | `version.md` against `origin/master` — duplicate and monotonicity | It is the only hook that sees the **remote**, and `commit-msg` provably does not run during a rebase, which is how duplicate versions get born |

⚠️ **`pre-push` runs no suite, and that is a choice:** a push that waits four
minutes becomes `--no-verify` the following week, and then the control is dead.
It asks two questions about one line of one file. **With no reachable remote it
degrades with a warning, never a refusal** — a guard that blocks work when it
cannot measure is a guard that gets switched off. Escape hatch declared in both:
`REPODOCS_NO_HOOK=1`.

---

## What this repository is

**repodocs is the documentation standard for the samirhvbr/Blue3 fleet.** It
holds no application: documentation, two git hooks, and a
[`templates/skeleton/`](templates/skeleton/) that a new repository copies out.

That makes the blast radius unusual. A change here does not affect one file — it
affects **every repository created from the skeleton afterwards**. Treat an edit
to `templates/skeleton/` or to `docs/conventions.md` as a change to the fleet,
not to a document. `.claude/settings.json` ships `defaultMode: plan` for that
reason.

---

## Golden rules

1. **`docs/conventions.md` is the single source of the norm.** When you cite it
   elsewhere, link it and mark the citation as an echo. Never fork the text.
2. **`.continue/` is the queue · `docs/` is the record · `CHANGELOG.md` is the
   history.** A document moves from queue to record the moment it describes
   something that already exists. A finished item **leaves** the queue.
3. **If a queue item needs half a page, it is in the wrong place.** Write it in
   `docs/` and leave one line and a pointer.
4. **In a contradiction between the queue and a document, the document wins.**
5. **Every prescriptive document declares its status** on the first lines:
   `ACTIVE` · `HISTORICAL` · `PROPOSED` · `DEPRECATED` · `NOT ADOPTED`. One
   with no declaration is read as `ACTIVE`, which is exactly the failure mode.
6. **A document made stale by a change is fixed in the same pass.** A document
   that ages in silence is worse than a missing one, because it has the
   authority of being written down.
7. **`CLAUDE.md` and `AGENTS.md` are byte-identical below the H1.** Edit one,
   edit the other ([ADR-007](docs/decisions.md)).
8. **Everything is versioned; the only exception is a secret.** `.claude/` and
   `.continue/` are tracked on purpose. A new `.gitignore` exception beyond
   secrets requires an ADR, never a silent line.
9. **Granting the agent a permission is the owner's act** — written into
   `.claude/settings.json` with its reason and how to revert it, never applied
   silently and never left as a promise in prose.
10. **A new decision becomes an ADR** in `docs/decisions.md`, in the same pass.

---

## Language

**English** for everything new, and for every edit to an existing document
(rule in force 02/09/2026 — [ADR-005](docs/decisions.md)). Nothing is rewritten
merely because of the rule: an old Portuguese document stays Portuguese until it
is touched again.

**Everything in this repository is English (US)** — documents, commit
messages, pull requests, issues, code comments, changelog entries.

**One carve-out, and only one:** end-user-facing strings — UI text,
transactional email, product copy. That is product i18n for a Brazilian
audience, not repository content.

Commit messages used to be a second carve-out and are not any more
([ADR-014](docs/decisions.md)). **Nothing is bilingual** — `LICENSE` is the plain
English MIT text, and a translated `README_br.md` pair is not the pattern.

Code identifiers are English, and always were.

---

## Version and commits (mandatory)

Format: `version - short description in English`. The version comes from
[version.md](version.md), **bumped in the same commit**:

- **Z** — documentation, wording, adjustment, a new section. The normal case.
- **Y** — a new locked decision (a new ADR) or a completed milestone.
- **X** — reserved; a stable release, by hand.

Forbidden: `feat:` / `fix:` / `chore:` prefixes and vague messages ("ajuste",
"update", "wip"). Several commits may share one version — group by subject, bump
in the first, repeat the number in the rest.

**Write the `CHANGELOG.md` entry first: its `## X.Y.Z - description` heading
*is* the commit subject.** Bodies are narrative — what changed, why, and what it
measured — not bullet lists.

**The version is the FIRST semver in `version.md`** — a bare string and a
markdown document both satisfy that, and both exist in this fleet
([ADR-012](docs/decisions.md)).

**Every version gets a tag named exactly after it — no `v` prefix — and a
published GitHub Release**, notes taken from its `CHANGELOG.md` section. The
workflow does it on every push that touches `version.md`; `tools/release.sh` is
the same logic for running it by hand. Both skip what already exists, so neither
can double-publish ([ADR-011](docs/decisions.md)).

**The `version.md` on GitHub equals the Releases on GitHub.** Your local checkout
does not enter the calculation — it can be behind, ahead or mid-work, and none of
that is published. A PR publishes nothing; the moment it merges, the Release
becomes that version.

**The bump and the Release are one act.** A commit that bumps `version.md` is not
finished until that version has a Release **and the `Latest` badge is on it** —
same push, not "later". The workflow does it; `./tools/release.sh` closes it by
hand and is idempotent, so running it is always safe and also repairs a drifted
badge.

Full rules, including why `version.md` and not an environment variable:
[docs/versioning.md](docs/versioning.md).

---

## Branch

Single branch, `master`. Direct push is allowed. **Force-push and deletion are
dead for everyone, the owner included** — a rewritten history is an audit trail
destroyed, and `.claude/settings.json` denies `--force`, `-f`, `reset --hard`
and `clean -fd` regardless of what the allow-list says.

---

## Before closing a version

- [ ] What changed is in `CHANGELOG.md`, with the **why**, not just the what.
- [ ] A new or changed document is in `docs/` — not in the queue, not in the
      commit body.
- [ ] A finished item **left** `.continue/`.
- [ ] A document made stale by this change was corrected in the same pass.
- [ ] `version.md` bumped, in this commit.
- [ ] The **tag and the GitHub Release** exist for this version. Normally the
      workflow does it on push; `./tools/release.sh` if you need it now.
- [ ] The twins still match: `diff <(tail -n +2 CLAUDE.md) <(tail -n +2 AGENTS.md)`.
- [ ] If `templates/skeleton/` changed, the root file it mirrors changed too —
      or the divergence is deliberate and written down.

---

<!-- RELEASES-RULE:repodocs -->

## Releases — the `version.md` on GitHub is what the Releases show

> Marked echo. The single source is **[samirhvbr/repodocs](https://github.com/samirhvbr/repodocs/blob/master/docs/versioning.md)**
> — change it there, not here. This block is regenerated.

**The `version.md` of the default branch, on GitHub, is what the GitHub Releases
must show.** The local checkout does not enter the calculation: it can be behind,
ahead or mid-work, and none of that is published — GitHub cannot tag a commit it
does not have.

**The bump and the Release are one act.** A commit that bumps `version.md` is not
finished until that version has a tag, a published Release, and the **`Latest`
badge on it** — the same push, not "later". A badge sitting on an older release
tells whoever looks that the project is at a version it is not.

- `.github/workflows/release.yml` does it on any push that touches `version.md`.
- `./tools/release.sh` does it by hand. It is **idempotent and self-healing**:
  it publishes whatever is missing and moves a drifted badge back. Running it is
  always safe, so it is both the check and the fix.

A PR publishes nothing while it is a PR. The moment it merges, the push moves
`version.md` on the default branch and the Release becomes that version.

Tag and Release title are the **bare version — no `v` prefix**.

## Language — English (US), everywhere in the repository

**Everything that lives in this repository, or in GitHub's interface around it,
is written in English (US)**: documents, **commit messages**, pull request titles
and bodies, issues, code comments, changelog entries, release notes.

Commit format: `X.Y.Z - short description in English`. The version comes from
`version.md` and is bumped in the same commit. Conventional Commits prefixes
(`feat:`, `fix:`, `chore:`) and vague one-word messages are forbidden.

**Exactly one carve-out:** end-user-facing strings — UI text, transactional
email, product copy. That is product i18n for a Brazilian audience, not
repository content.

History is not rewritten: Portuguese messages already in the log stay as they
are.

<!-- /RELEASES-RULE -->
