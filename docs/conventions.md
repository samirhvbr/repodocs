# Documentation convention — samirhvbr/Blue3 fleet

> **Status:** `ACTIVE` · Written 29/08/2026 (as `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md`) · Moved here and translated 02/09/2026 · **Single source.**
>
> Applies to **every** repository in the fleet. The others carry a pointer here
> from their `.continue/README.md` — on purpose: a rule that lives inside one
> repository is invisible to whoever opens another.

## Why this exists

A folder named `.continue/` carries an implicit contract: **"this still needs to
be done."** A finished document sitting there lies about its own state — and the
lie is not abstract, it has already been expensive here:

- **WCUP:** seven documents written in the tone of a pending plan described work
  that had **already shipped**. Anyone opening them in 2030 would conclude the
  project was abandoned half-built. It was not.
- **ONLINE:** the brief reads "almost done" and hides that of the four parts
  that make the product (probe, target, ping, alert), **none** exists.
- **INTRANET:** an entire design system sat in the queue with
  `Status: NÃO ADOTADO` on the first line, describing a palette that was never
  applied.

The cost is not untidiness. It is **a confident wrong decision, taken by
someone who read the folder and believed it.**

---

## 1. `.continue/` is the queue · `docs/` is what has been produced

| Folder | What it is | The question it answers |
|---|---|---|
| `.continue/` | **Queue** | "what is still missing here?" |
| `docs/` | **Record** | "how is/was this done, and why?" |
| `CHANGELOG.md` | **History** | "what happened, when, and why?" — never rewritten |

Both `.continue/` and `docs/` are **git-tracked on purpose**. Context that does
not travel with the checkout is context the next machine does not have.

### The trigger — when one becomes the other

A document leaves `.continue/` for `docs/` **the moment it describes something
that already exists**. Three ways that happens:

1. **The work shipped.** A brief, plan or spec whose content is now in the code.
   → goes to `docs/`, and the permanent record of *when* is `CHANGELOG.md`.
2. **The project froze or was postponed.** The queue stops being a queue.
   → the material becomes history; only what is still a **decision** stays.
3. **The document was never a queue item.** A survey, a measurement, a contract,
   a runbook, an ADR.
   → it is born in `docs/`. It does not pass through `.continue/`.

> **A finished item leaves the queue.** A queue holding an already-done item
> costs **more** than an incomplete queue: it leads the next session to redo
> work.

### If an item needs half a page, it is in the wrong place

Write it in `docs/` and leave **one line and a pointer** in the queue. Copying
the detail into the queue creates a second source of truth, and the next session
cannot tell which of the two to follow.

**When the queue and a repository document contradict each other: the document
wins.**

---

## 2. An emptied `.continue/` requires a `README.md` saying where the docs went

Without it, moving a document only trades **"it misleads whoever opens it"** for
**"nobody can find it."**

The queue's `README.md` must answer, in this order:

1. **What is left here**, and why it is still queue.
2. **Where what left went**, with a relative link.
3. **Which decision is pending**, if any, and whose it is.

Live example: `ONLINE/.continue/README.md` opens by saying the only outstanding
item is a decision by the owner, and warns that the brief **must not be read as
a queue**.

---

## 3. A filename carries state

The name is read **before** the content, and sometimes instead of it. A name
that hides the state hands the reader the job of discovering that the document
does not apply.

| Bad name | Good name | Why |
|---|---|---|
| `BLUE3_DESIGN.md` | **`DESIGN_SYSTEM_NAO_ADOTADO.md`** | The content opens with `Status: NOT ADOPTED`. The new name warns before anyone invests the reading |
| `escopo.md` | `ESCOPO-E-FASES.md` | Says there are phases, and that the document covers the whole arc |
| `wait.md` | (kept) | It is a real queue item; the name does not lie |

When the state changes, **the name changes with it**. Renaming is cheap; reading
the wrong document is not.

### The status vocabulary

Every document that **prescribes** something — architecture, design, API,
schema, security, process — declares its own status at the top, on one line:

`ACTIVE` · `HISTORICAL` · `PROPOSED` · `DEPRECATED` · `NOT ADOPTED`

**Why it is mandatory:** documentation that looks normative but was never
adopted is worse than no documentation — it gets followed.

A document with no status declaration is read as `ACTIVE` by default, which is
exactly the failure mode above. Declare it.

---

## 4. A document in `docs/` is a release gate

Delivery without a record is delivery nobody can audit later. **Before closing a
version:**

- [ ] What changed is in `CHANGELOG.md`, with the **why**, not just the what.
- [ ] A new or changed document is in `docs/` — not in the queue, not in the
      commit body.
- [ ] A finished item **left** `.continue/`.
- [ ] A document made **stale by this delivery** was corrected in the same pass.

That last one is what escapes most often. Real examples:

- F1's `wait.md` listed the pit-stop bug as a deploy blocker **after** the
  fallback was already implemented and switched on;
- the BRASILEIRÃO scope carried the wrong domain and database
  (`brasileirao.blue3.com.br`, `brasileirao_a_2026`) while the server was
  running `bra.blue3.com.br` and `blue3_bra_2026`.

**A document that ages in silence is worse than a missing one**, because it has
the authority of being written down.

---

## 5. A plan is a `.md` for Claude Code to execute · a `.sh` is server diagnostics

| Format | What for | Why |
|---|---|---|
| **`.md`** | **A plan** — Claude Code reads it and executes, deciding case by case | A plan involves judgement: "if X, do Y; if not, stop and report". A script does not judge |
| **`.sh`** | **Server diagnostics** — collects state, changes nothing | What needs to run on the server, read config, measure. **Read-only** |

**Rules for a diagnostic `.sh`:**

- **It changes nothing** — no file, service, firewall or database. If it changes
  something, it became a plan and it is in the wrong format.
- **It prints no secret.** A credential appears as `[N chars]` or as a truncated
  `sha256` fingerprint, never as its value.
- **It says what it does NOT do**, in a comment at the top.
- **The exit code is part of the contract** when there is a verdict. Example:
  `liga:descobrir` exits `2` when it is **blocked**, so that no script confuses
  "it ran" with "you may proceed".

Live example: `diag-pentest-superficie.sh` answers *where* to change something
before any plan says *what* to change. Without it, a `Require ip` would have been
written into the wrong file.

---

## 6. Measurement traps already paid for

Recorded because each one produced a confident, wrong conclusion:

- **`HTTP 200` does not prove a route exists.** An app that returns the home
  page for an unknown route scores 200 on everything. Check the **body**, not
  just the code.
- **`curl` against MEUIP's home page receives the plain-text API**, not the
  HTML — that is the project's purpose. Auditing the page requires a browser
  `User-Agent`.
- **A `config:cache` newer than the `.env` means the `.env` does not apply.**
  Editing a variable without rebuilding the cache is invisible work.
- **The server's `git log` does not tell you the deployed version** when the
  deploy copies files. The authority is `version.md` — or, now, `curl <host>/version`.
- **`/proc/PID/environ` is the environment at `exec` time**, not the current one.
  A parent shell looks "clean" while the child has the variable.
- **A Blade component does not emit its own name** into the HTML. Grepping the
  output for `<x-f1.tower>` returns zero even while the component renders.

---

## 7. The repository file standard

Every repository in the fleet carries these at the root. Exact names — the
naming is the convention, and tooling depends on it.

| File | Who reads it | Rule |
|---|---|---|
| `README.md` | humans, GitHub | What the project is and how to run it. English. |
| `version.md` | the app, the hooks, the deploy | A **bare `X.Y.Z` string**, nothing else. The single authority on the version. See [versioning.md](versioning.md). |
| `CLAUDE.md` | Claude Code | Agent instructions. |
| `AGENTS.md` | other agent tooling (agents.md standard) | **Byte-identical to `CLAUDE.md` below the H1.** Edit one, edit the other. |
| `SECURITY.md` | GitHub, whoever reports a vulnerability | Thin, at the root because that path is what triggers GitHub's *"Report a vulnerability"*. Points at the normative source; does not duplicate it. |
| `CHANGELOG.md` | humans, the commit automation | Newest first. Each `## X.Y.Z - description` heading **is** the commit message. |
| `LICENSE` | GitHub, lawyers | **No extension.** GitHub detects both spellings; extensionless is the fleet's, 41 files to 1. |
| `NOTICE` | GitHub, lawyers | **No extension.** Third-party attribution a license requires. **It must never contradict `LICENSE`** about the license or the copyright holder. |
| `.gitignore` | git | Everything is versioned; **the only exception is a secret.** `.claude/` and `.continue/` are tracked on purpose. |

And these directories:

| Path | Rule |
|---|---|
| `.claude/` | Model profile and permission posture, versioned. `settings.local.json` is the machine-local part and stays gitignored. Granting a permission is the owner's act, written with its reason. |
| `.continue/` | The queue (§1), with a mandatory `README.md` (§2). |
| `docs/` | The record (§1), with a curated `README.md` index. `docs/decisions.md` is the ADR log — the strongest convention in the fleet, present in every repo. |
| `.github/` | `CODEOWNERS`, `dependabot.yml`, workflows. |
| `tools/git-hooks/` | Hooks, enabled once per clone with `git config core.hooksPath tools/git-hooks`. |

> A repository may **trim** this set with a reason — SHVIA-SITE is a static
> marketing site and correctly has no `SECURITY.md` or `.continue/`. Trimming
> deliberately is fine. Missing a file by accident is not: SHVIA-DESKTOP shipped
> without a `LICENSE` while its siblings all have the same one, which is an
> oversight, not a decision.

---

## 8. Language

**Rule in force since 02/09/2026:** every new document, and every edit to an
existing document, inside a repository that goes to GitHub is written in
**English**. That covers `README.md`, `CLAUDE.md`, `AGENTS.md`, anything under
`docs/`, code comments, changelog prose, PR messages and issue descriptions.

Nothing gets rewritten just because of this rule. An old Portuguese document
stays Portuguese until it is touched again — at which point the edit (or the
whole file, when practical) comes out in English.

**Two carve-outs, stated here so nobody re-litigates them:**

| Stays Portuguese | Why |
|---|---|
| **Commit messages** — `versão - comentário em português` | The per-repo commit convention is unchanged. See [versioning.md](versioning.md). |
| **End-user-facing strings** — UI text, transactional email, product copy | That is product i18n for a Brazilian audience, not technical documentation. |

**Nothing else, and nothing bilingual.** `LICENSE` is the plain English MIT text
— not a PT/EN presentation ([ADR-010](decisions.md)). A `README_br.md` beside a
`README.md` is not the pattern either: a translated pair is two documents that
drift, and BLUE3-INTRANET's pair proves it, at 374 lines against 259.

Code identifiers — class, method, variable and column names — are English, and
always were.

---

## 9. Where this convention applies

Every repository in the fleet. Each one carries a pointer here in its
`.continue/README.md`.

**If you are reading this inside a repository that is not repodocs, this file is
a copy or a link — the source is** `samirhvbr/repodocs/docs/conventions.md`.

Until 02/09/2026 the source was `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md`.
It moved because a fleet-wide norm living inside one product repository is
invisible to whoever opens another — the exact problem the note at the top of
this file describes. See [ADR-001](decisions.md).
