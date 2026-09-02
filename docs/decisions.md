# Decisions (ADR log)

> **Status:** `ACTIVE` · The single, chronological record of decisions taken in
> this repository. Format: Architecture Decision Record.

An ADR records a decision **and the reason it was taken**, so that the next
session does not re-litigate it. A how-to does not argue direction — it links
the ADR.

Numbering is sequential and never reused. A superseded ADR is not deleted: its
status changes to `SUPERSEDED` and it names the ADR that replaced it.

---

## ADR-001 — repodocs is the fleet's documentation standard

**Status:** `ACCEPTED` · 02/09/2026

**Context.** `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` (157 lines,
written 29/08/2026) already declared itself *"single source, applies to every
repository in the fleet"*. Its own §7 admitted the awkwardness: the source of a
fleet-wide norm was a path inside one product repository. A rule that lives
inside one repo is invisible to whoever opens another — which is the same
failure the document itself was written to prevent.

**Decision.** `samirhvbr/repodocs` is the home of the fleet documentation
standard. The norm lives at [`docs/conventions.md`](conventions.md), in English.
Each repository points here from its `.continue/README.md`.
`BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` becomes a pointer to this file.

**Consequences.** There is one place to change the norm and many places that
reference it. Retrofitting the pointer into the sibling repositories is a
separate, explicit pass — it has not been done yet, so until then two copies of
the norm exist and **this one is the source.**

---

## ADR-002 — `version.md` is the sole authority on the version

**Status:** `ACCEPTED` · 02/09/2026

**Context.** 63 repositories carry a `version.md`; one carries a `VERSION`. The
file is git-tracked so the bump travels inside the commit, which an environment
variable cannot do when `.env` is excluded from the deploy.

**Decision.** `version.md` at the root, a bare `X.Y.Z` string, is the single
authority. An environment variable may exist only as a fallback when the file is
absent, and no document may describe it as the authority.

**Consequences.** Settles the live contradiction in `BLUE3-INTRANET`, where the
`README.md` said `version.md` had been removed in favour of `APP_VERSION` while
the file existed and `CLAUDE.md` called it authoritative. See
[versioning.md](versioning.md).

---

## ADR-003 — commit format `versão - comentário em português`

**Status:** `ACCEPTED` · 02/09/2026

**Context.** The format is already normative and identical in EOP,
SHVIA-DESKTOP, SHVIA-SITE, SHVIA-WEB and BLUE3-INTRANET, and all five explicitly
ban Conventional Commits prefixes.

**Decision.** The subject is `X.Y.Z - comentário em português`. The version comes
from `version.md`, bumped in the same commit. `feat:`/`fix:`/`chore:` and vague
comments are rejected. Several commits may share one version; only the first
bumps.

**Consequences.** The version, not a type prefix, is what makes `git log`
searchable across the fleet. Enforced mechanically by
[`tools/git-hooks/commit-msg`](../tools/git-hooks/commit-msg).

---

## ADR-004 — `.continue/` is the queue, `docs/` is the record, `CHANGELOG.md` is the history

**Status:** `ACCEPTED` · 02/09/2026 · Inherited from the 29/08/2026 convention

**Context.** A folder named `.continue/` carries the implicit claim "this still
needs doing". Finished documents left there produced confident wrong readings in
WCUP, ONLINE and INTRANET.

**Decision.** Three tiers with one trigger: a document moves from the queue to
the record **the moment it describes something that already exists**. A finished
item leaves the queue. An emptied queue keeps a `README.md` saying where its
contents went. In a contradiction between queue and record, the record wins.

**Consequences.** Both folders stay git-tracked on purpose. Detail never lives
in the queue — one line and a pointer. See
[conventions.md §1–§2](conventions.md#1-continue-is-the-queue--docs-is-what-has-been-produced).

---

## ADR-005 — documentation in English from 02/09/2026

**Status:** `ACCEPTED` · 02/09/2026

**Context.** The repositories are readable by collaborators and tooling that do
not read Portuguese. The rule is the owner's personal preference for his own
projects, recorded in `~/.claude/CLAUDE.md`; it is not a security or compliance
requirement.

**Decision.** Every new document, and every edit to an existing one, inside a
repository that goes to GitHub is written in English. Nothing is rewritten
merely because of this rule: an old Portuguese document stays Portuguese until
it is touched again.

**Three carve-outs stay Portuguese:** commit messages (ADR-003), end-user-facing
strings (product i18n for a Brazilian audience), and `LICENSE` (ADR-006).

**Consequences.** For a transition period a repository holds documents in both
languages. That is expected and is not a defect. Some repos already run the
bilingual `README.md` + `README_br.md` pair; that pair is allowed, and both
halves must be kept in sync — BLUE3-INTRANET's drifted to 374 lines against 259,
which is the failure mode to avoid.

---

## ADR-006 — `LICENSE` and `NOTICE` without extension; MIT, bilingual

**Status:** `ACCEPTED` · 02/09/2026

**Context.** The fleet carries 41 `LICENSE` files against 1 `LICENSE.md`, and 11
`NOTICE` against zero `NOTICE.md`. GitHub's detector recognises both spellings,
so the choice is convention, not capability. Fourteen repositories share a
byte-identical MIT text presented bilingually PT-then-EN.

**Decision.** `LICENSE` and `NOTICE`, no extension. MIT, bilingual,
`Copyright (c) 2026 Samir Hanna Verza`, byte-identical to the fleet's text.
**`NOTICE` must never contradict `LICENSE`** about the license or the copyright
holder.

**Consequences.** Settles the live contradiction in SHVIA-WEB, whose `LICENSE`
says MIT under a personal copyright while its `NOTICE` says
*"Copyright (c) Blue3. Proprietary software"*. Those cannot both be true; this
repository's `NOTICE` agrees with its `LICENSE`. The bilingual `LICENSE` is a
deliberate carve-out to ADR-005 — legal text, and diverging one repository for a
style reason would make the fleet's licenses non-identical.

---

## ADR-007 — `CLAUDE.md` and `AGENTS.md` are twin files, identical below the H1

**Status:** `ACCEPTED` · 02/09/2026

**Context.** Three shapes exist in the fleet: BLUE3-INTRANET symlinks
`AGENTS.md` to `CLAUDE.md`; EOP and SHVIA-DESKTOP keep twin real files with a
mirroring comment; SHVIA-WEB let them diverge into different roles (strict rules
vs. full stack guide).

**Decision.** Twin **real files**, byte-identical below the H1, each carrying an
HTML comment stating the mirroring contract. Only the H1 differs.

**Consequences.** A symlink is smaller but does not survive a Windows checkout
and is not followed by every tool that reads `AGENTS.md`. The cost is that an
edit must be applied twice; the mirroring comment says so, and the check is one
`diff`. SHVIA-WEB's deliberate divergence stays valid for a repository large
enough to need two documents — but then the split is a decision to record, not a
drift to discover.

---

## ADR-008 — every prescriptive document declares its status

**Status:** `ACCEPTED` · 02/09/2026 · Inherited from BLUE3-INTRANET

**Context.** An entire design system sat in INTRANET's queue with
`Status: NÃO ADOTADO` on its first line. The tag is what stopped it from being
implemented. Documents without one were read as current and followed.

**Decision.** Every document that prescribes something — architecture, design,
API, schema, security, process — declares its status on one line at the top:
`ACTIVE` · `HISTORICAL` · `PROPOSED` · `DEPRECATED` · `NOT ADOPTED`.

**Consequences.** A document with no declaration is read as `ACTIVE` by default,
which is precisely the failure mode. When the state changes, the **filename**
changes with it as well — `DESIGN_SYSTEM_NAO_ADOTADO.md` warns before anyone
invests the reading.

---

## ADR-009 — no CI workflow in this repository

**Status:** `ACCEPTED` · 02/09/2026

**Context.** repodocs holds documentation, two shell hooks and a template
skeleton. There is nothing to compile and no suite to run.

**Decision.** `.github/` carries `CODEOWNERS` and `dependabot.yml` only. The
mechanical checks that matter here — commit format and version monotonicity —
run in `tools/git-hooks/`, at the moment they can still prevent the mistake.

**Consequences.** No build badge. A red CI on a documentation repository teaches
people to ignore CI, and an ignored check is worse than an absent one. If a
docs-lint is ever written for this fleet, it enters as a `pre-commit` hook first
and a workflow second — the EOP topology, where each of the three hooks exists
because the other two cannot reach its moment.
