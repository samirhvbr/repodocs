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

**Status:** `ACCEPTED` · 02/09/2026 · **Amended by
[ADR-012](#adr-012--the-version-is-the-first-semver-in-versionmd) (02/09/2026)**
— the authority stands; the claim that the file is "a bare `X.Y.Z` string and
nothing else" was measured false for a third of the fleet and was corrected.

**Context.** 63 repositories carry a `version.md`; one carries a `VERSION`. The
file is git-tracked so the bump travels inside the commit, which an environment
variable cannot do when `.env` is excluded from the deploy.

**Decision.** `version.md` at the root is the single authority.
*(As originally written this ADR also required the file to be a bare `X.Y.Z`
string. ADR-012 replaced that with the first-semver rule.)* An environment variable may exist only as a fallback when the file is
absent, and no document may describe it as the authority.

**Consequences.** Settles the live contradiction in `BLUE3-INTRANET`, where the
`README.md` said `version.md` had been removed in favour of `APP_VERSION` while
the file existed and `CLAUDE.md` called it authoritative. See
[versioning.md](versioning.md).

---

## ADR-003 — commit format `X.Y.Z - description`

**Status:** `ACCEPTED` · 02/09/2026 · **Language clause superseded by
[ADR-014](#adr-014--everything-in-a-repository-is-english-us-commit-messages-included)
(03/09/2026)** — the shape stands, the Portuguese requirement does not.

**Context.** The format is already normative and identical in EOP,
SHVIA-DESKTOP, SHVIA-SITE, SHVIA-WEB and BLUE3-INTRANET, and all five explicitly
ban Conventional Commits prefixes.

**Decision.** The subject is `X.Y.Z - description`. The version comes
from `version.md`, bumped in the same commit. *(As originally written the
description had to be in Portuguese; ADR-014 made it English.)* `feat:`/`fix:`/`chore:` and vague
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

**Carve-outs:** originally three, then two after
[ADR-010](#adr-010--nothing-bilingual-license-is-the-plain-english-mit-text)
removed `LICENSE`, and **one** after
[ADR-014](#adr-014--everything-in-a-repository-is-english-us-commit-messages-included)
removed commit messages. What remains is end-user-facing strings — product i18n
for a Brazilian audience.

**Consequences.** For a transition period a repository holds documents in both
languages. That is expected and is not a defect — what is not allowed is one
*document* in two languages, whether inside a single file or as a
`README.md` + `README_br.md` pair (ADR-010).

---

## ADR-006 — `LICENSE` and `NOTICE` without extension; MIT

**Status:** `ACCEPTED` · 02/09/2026 · **The bilingual half is `SUPERSEDED` by
[ADR-010](#adr-010--nothing-bilingual-license-is-the-plain-english-mit-text)
(02/09/2026).** The extensionless naming, the MIT choice, the copyright holder
and the NOTICE-agrees-with-LICENSE rule all stand.

**Context.** The fleet carries 41 `LICENSE` files against 1 `LICENSE.md`, and 11
`NOTICE` against zero `NOTICE.md`. GitHub's detector recognises both spellings,
so the choice is convention, not capability. Fourteen repositories share a
byte-identical MIT text presented bilingually PT-then-EN.

**Decision.** `LICENSE` and `NOTICE`, no extension. MIT,
`Copyright (c) 2026 Samir Hanna Verza`. **`NOTICE` must never contradict
`LICENSE`** about the license or the copyright holder.

*(As originally written this ADR also specified the bilingual PT-then-EN
presentation, to stay byte-identical to the fleet's fourteen copies. ADR-010
reversed that part.)*

**Measured cost (02/09/2026).** GitHub's license detector reports `Other`, not
`MIT License`, for every repository carrying the bilingual text — this one,
SHVIA-WEB, SHVIA-SITE, BLUE3-AI-LOGIN. Control: `skill-LOOP`, which carries the
plain English MIT, is detected as `MIT License`. The detector compares the whole
file against a template and the Portuguese half drops the similarity below its
threshold. The license *is* MIT regardless; what is lost is the sidebar badge and
API-level detectability. **This measurement is what ADR-010 acted on**, the same
day.

**Consequences.** Settles the live contradiction in SHVIA-WEB, whose `LICENSE`
says MIT under a personal copyright while its `NOTICE` says
*"Copyright (c) Blue3. Proprietary software"*. Those cannot both be true; this
repository's `NOTICE` agrees with its `LICENSE`. Those cannot both be true.

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

**Status:** `ACCEPTED` · 02/09/2026 · **Narrowed by
[ADR-013](#adr-013--a-release-workflow-is-not-a-ci-workflow) (02/09/2026)** —
this bans a **build/test** workflow, not every workflow.

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

---

## ADR-010 — nothing bilingual; `LICENSE` is the plain English MIT text

**Status:** `ACCEPTED` · 02/09/2026 · Supersedes the bilingual clause of
[ADR-006](#adr-006--license-and-notice-without-extension-mit) and revises the
carve-out list of [ADR-005](#adr-005--documentation-in-english-from-02092026)

**Context.** ADR-006 kept `LICENSE` bilingual — Portuguese text, then English —
so that the file would stay byte-identical across the fourteen repositories that
already carried it. The measurement recorded in ADR-006 showed what that costs:
GitHub reports `licenseInfo: Other`, not `MIT License`, for every one of them,
because its detector compares the whole file against a template and the
Portuguese half drops the similarity below the threshold. The control was
`skill-LOOP`, whose plain English MIT **is** detected.

The owner's decision, on being shown the measurement: **no bilingual anything.**

**Decision.** `LICENSE` carries the plain English MIT text, byte-identical to
the canonical one. No PT/EN presentation in a single file, and no translated
companion — a `README_br.md` beside a `README.md` is not the pattern either.

The English documentation rule (ADR-005) now has **two** carve-outs, not three:
commit messages and end-user-facing strings. `LICENSE` is no longer one.

**Consequences.** GitHub detects the license again, which is the point — the
sidebar badge and API-level detectability come back. The cost is that this
repository's `LICENSE` is **no longer byte-identical to the fleet's fourteen
other copies**; it is byte-identical to the canonical MIT instead. That
divergence is the correct direction and is expected to be closed by replacing
the bilingual copies, not by reverting this.

Retrofitting the English `LICENSE` into the sibling repositories is part of the
same pass as [ADR-001](#adr-001--repodocs-is-the-fleets-documentation-standard);
it has not been done, and it is the owner's to schedule.

A translated pair is rejected for the same reason a copied norm is: two
documents saying the same thing drift, and one of them becomes wrong in silence.
BLUE3-INTRANET's `README.md`/`README_br.md` pair is the worked example, at 374
lines against 259.

---

## ADR-011 — every version gets a tag named after it and a published Release

**Status:** `ACCEPTED` · 02/09/2026

**Context.** Measured across the fleet on 02/09/2026, in a full census of 52
repositories carrying a `version.md`:

- **50 of 52 have zero published Releases.**
- **47 of 52 have zero version tags.**
- **~2,764 distinct version numbers** exist across the fleet's histories.
  EOP (827) and SHVIA-WEB (764) alone are over half of them.

Every repository versions its commits — `2.110.161 - …` — but GitHub never
infers a version from a commit subject, so those pages say *"No releases
published"* and `git diff 2.110.160..2.110.161` fails because neither name
exists as a ref.

**Five repositories already do this, and all five use a `v` prefix:**
`SSHVTERM-DESKTOP` (22 tags, **17 published Releases**, titled `ShvTerm v0.5.41`),
`brasileirao-a-2026` (17 tags), `blue3-wcup-2026` (3), `blue3-f1` (1), and the
colleague-owned `docsys_blue3` (19 tags, 18 Releases — outside this fleet).

> ⚠️ **A first pass of this ADR said "zero published Releases and three tags
> between all of them".** That was written from a partial scan — the local
> `~/x` walk plus the BLUE3-ISP org — and it missed `SSHVTERM-DESKTOP` entirely.
> The real numbers are above. Corrected in `1.2.1`, from the full census.

Two repositories carried the gap **in writing**, in their own `version.md`:
`blue3-f1` — *"Ao publicar, taggear `v0.3.0`"* — and `brasileirao-a-2026` —
*"⚠️ Sem tag `v0.16.0` no git. As tags param em `v0.15.0`."* Known debt, not a
new idea.

**Decision.** Every version in `version.md` gets a git tag **named exactly as
the file holds it — no `v` prefix** — and a GitHub Release on that tag, titled
with the same string, whose notes are the `CHANGELOG.md` section for that
version. The whole history is backfilled, not just new versions.

Two owners, both guarding on *"does this tag already exist?"*, so whichever runs
first wins and the other is a no-op:
`.github/workflows/release.yml` on every push that touches `version.md`, and the
COMMITTER skill right after its own push succeeds. Both call the same
`tools/release.sh`.

**The authority is the remote, never the working tree** — stated by the owner as
*"o version.md do GitHub = Releases do GitHub"*. `release.sh` reads `version.md`
from `origin/<default branch>` and tags that commit, falling back to `HEAD` only
when the remote ref is not resolvable (the CI case, where `HEAD` **is** the
pushed commit). A local file that disagrees produces a note, not a different
Release.

This is what makes the PR flow work with nothing to remember: a branch at
`1.3.25` publishes nothing while it is a branch; the merge pushes `version.md`
to the default branch, the workflow fires, and the Release becomes `1.3.25`.

It also fixes a real class of error rather than a hypothetical one. Measured the
same day: `sshvterm-desktop` held `1.3.19` locally against `1.2.80` on the
remote (8 unpushed commits), and `shvia-web` held `2.110.154` against
`2.110.161`. Publishing from the working tree would have tagged commits GitHub
does not have.

**Consequences.** `git diff <old>..<new>` works across the whole history, and a
bad deploy has a ref to roll back to.

The `v`-less form **diverges from the 43 `v*` tags the five repositories above
already carry**, and the owner confirmed it after being shown that number: bare
tags everywhere, including in those five. The accepted consequence is stated
plainly, because it is real — `SSHVTERM-DESKTOP` will hold `v0.5.41` with its
published Release *"ShvTerm v0.5.41"* **alongside** a new bare `0.5.41`: the same
version reachable under two names. Old tags are not deleted, because deleting
them would orphan 17 Releases that already exist and that people may have
linked.

What is corrected instead are the two `version.md` files whose text instructs
the `v` form — a document contradicting the artefact is the defect, not the old
tag.

Neither owner ever decides a version: both copy a number the agent already
wrote, which is what leaves COMMITTER's inviolable *"nunca bumpa versão"* rule
(its own ADR-002) untouched.

The backfill is roughly **2,764 Releases** fleet-wide and is **hard to undo** —
deleting them costs the same volume of API calls again. The mitigation is a
dry-run printed and read per repository before anything is published, plus a
script that is idempotent and resumable. That was the accepted cost, not an
oversight.

---

## ADR-012 — the version is the first semver in `version.md`

**Status:** `ACCEPTED` · 02/09/2026 · Amends
[ADR-002](#adr-002--versionmd-is-the-sole-authority-on-the-version)

**Context.** ADR-002 stated that `version.md` is *"a bare `X.Y.Z` string and
nothing else"*. Measured, that is true of EOP, SHVIA-WEB, repodocs,
`blue3-site-front`, `online` and `blue3-ndrive-server` — and **false** for nine
BLUE3-ISP repositories and for skill-COMMITTER itself, whose `version.md` is a
full markdown document opening with `**Versão atual:** ` and a backticked
number, followed by the versioning convention and an embedded changelog.
`blue3-intranet-mobile` holds two lines: `2.1.9`, then `api_min: 0.1.0`.

Those repositories already document the real rule — *"quem precisar exibir ou
reportar a versão extrai o primeiro número semver (`X.Y.Z`) encontrado aqui"* —
and `config/app.php` has implemented it all along with
`preg_match('/\d+\.\d+\.\d+/')`.

**Decision.** **The version is the first semver in `version.md`**, whatever the
file's shape. Every reader — the app, the hooks, `tools/release.sh`, the
workflow, the COMMITTER skill — uses that one rule. A new repository uses the
bare form because it is the simplest thing satisfying it; an existing file is
**not** reshaped, because the rule already reads it and rewriting it would change
nothing.

**Consequences.** The norm stops being false for a third of the fleet. This is
the second time this repository has published a rule that the fleet contradicted
— the first was the bilingual `LICENSE` costing the MIT badge (ADR-010). Both
were caught by measuring rather than by re-reading, which is the argument for
measuring before writing a norm, not after.

---

## ADR-013 — a release workflow is not a CI workflow

**Status:** `ACCEPTED` · 02/09/2026 · Narrows
[ADR-009](#adr-009--no-ci-workflow-in-this-repository)

**Context.** ADR-009 said there is no workflow here, reasoning that nothing
compiles and no suite runs, and that *"a red CI on a documentation repository
teaches people to ignore CI"*. ADR-011 then required a workflow to publish
Releases.

**Decision.** ADR-009 bans a **build/test** workflow. A workflow that *publishes*
is a different thing and is allowed. `.github/workflows/release.yml` exists here
and in the skeleton.

**Consequences.** The distinction holds because of what a failure means. A red
test workflow on a docs repo is noise, and noise trains people to ignore the
signal. The release workflow is silent in its normal case — the tag for the
current version almost always already exists, so it exits clean — and when it
does fail it means a Release is genuinely missing, which is worth a red mark.

It also **never fails a push**: no `version.md`, no `tools/release.sh`, no
parseable version — all exit 0 with a notice. A guard that blocks work when it
cannot measure is a guard that gets switched off, which is the same reasoning
already written into `pre-push`.

---

## ADR-014 — everything in a repository is English (US), commit messages included

**Status:** `ACCEPTED` · 03/09/2026 · Supersedes the language clause of
[ADR-003](#adr-003--commit-format-xyz---description) and narrows
[ADR-005](#adr-005--documentation-in-english-from-02092026) to a single carve-out

**Context.** ADR-005 put documentation in English but kept commit messages in
Portuguese, on the reasoning that the commit convention was a separate,
per-repo rule. The owner rejected that split on seeing it applied — the trigger
was a commit this very rollout had just written across the fleet:

> `1.0.1 - Regra de Releases no doc de agente: bump e Release sao um ato so`

*"precisamos documentar a regra de que commits tambem, tudo em ingles"* ·
*"todo commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*

The split does not survive contact with where a commit message is actually read.
It is not a private note: it shows up in `git log`, in `git blame`, in the diff
of a pull request, in the body of a Release, and in the changelog entry it was
copied from. That is precisely the surface ADR-005 wanted in English — the one a
collaborator or a tool that does not read Portuguese meets first.

**Decision.** **Everything in a repository, and in GitHub's interface around it,
is English (US).** Documents, commit messages, pull request titles and bodies,
issues, code comments, changelog entries, release notes.

**Exactly one carve-out remains:** end-user-facing strings — UI text,
transactional email, product copy. That is product i18n for a Brazilian
audience, and a Brazilian user does not read the repository.

**Consequences.** Existing Portuguese commit messages stay as they are: history
is not rewritten, and the fleet's `git log` will read bilingual across the
03/09/2026 boundary. That is the same shape ADR-005 already accepted for
documents, and for the same reason — rewriting to satisfy a style rule costs
more than it buys.

**What enforces it, and what does not.** `tools/git-hooks/commit-msg` checks the
**shape** (`X.Y.Z - description`), rejects Conventional Commits prefixes and
rejects vague one-word messages — its reject list gained the English ones
(`cleanup`, `changes`, `tweak`, `stuff`, `refactor`) alongside the Portuguese
ones already there. It does **not** check the language, and deliberately so:
detecting language mechanically is guesswork, and a guard that fires on a false
positive is a guard that gets bypassed. The shape is mechanical; the language is
the norm's job and the author's.

**The `.committer.yml` skill follows.** Its fallback prompt asked the model for
a Portuguese message; leaving that would have made the automation contradict the
norm on every commit it wrote.
