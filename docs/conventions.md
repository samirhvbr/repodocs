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

**A document leaves `.continue/` when, and only when, the thing it describes
exists.** Existence is the single exit condition. Length is not an exit
condition. Neither is age, language, untidiness, the end of a session, or the
arrival of an agent who would have written it differently.

> `tela.md` says *"a black screen with a yellow ball in the middle"*. It leaves
> the queue when there is a black screen with a yellow ball. Until then it stays,
> at any length, in whatever shape it is in — because until then it is the only
> place that thing exists.

**"Produce", applied to a queue item, means making the thing exist.** Not
editing the document, not translating it, not promoting it to `docs/`. The
document is the specification; the deliverable is the thing. Producing it closes
the item, and removing the document is the **last step of the commit that
contains the work** — never a step of its own.

**No agent empties this folder as tidying.** A queue item deleted without the
work being done destroys the only artefact a project has before it has code, and
it is worse than losing a file: what usually replaces it is a `docs/` page
describing a screen nobody built, carrying the authority of the record.

Three ways a document legitimately leaves:

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

### If an item needs half a page **to describe something that already exists**, it is in the wrong place

Write it in `docs/` and leave **one line and a pointer** in the queue. Copying
the detail into the queue creates a second source of truth, and the next session
cannot tell which of the two to follow.

**This rule is about a record that ended up in the queue, and about nothing
else.** It has no opinion on the length of a specification of work not yet done:
a 1,300-line brief describing something unbuilt is not in the wrong place, it is
in the only place it can be. Read as a size limit it contradicts the trigger
above, and the contradiction has a direction — the trigger wins, always. A long
queue item is a project with a lot still to build.

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
- [ ] A change in behavior carries the test that fails when it breaks, and the
      pertinent tests **ran** — or the changelog entry says why not and what was
      checked instead ([§9](#9-a-change-in-behavior-ships-with-the-test-that-fails-when-the-behavior-breaks)).
- [ ] **The work is committed** — by the agent that did it, as the last step of
      the task and before it is reported as finished, split into one commit per
      subject when the delivery covered more than one
      ([versioning.md](versioning.md#who-commits-and-when), [ADR-016](decisions.md)).
- [ ] The **tag and the GitHub Release** for this version exist, **and the
      `Latest` badge is on it**. The bump and the Release are one act, not two —
      a version with no tag is a number in a commit message (`git diff` cannot
      reach it, and a bad deploy has nothing to roll back to), and a badge on an
      older release says something false about the project. One command checks
      and fixes both: `./tools/release.sh`
      ([versioning.md](versioning.md#the-bump-and-the-release-are-one-act)).

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
- **A one-line `grep` over a whole document does not read its status header.**
  Auditing nine documents with one alternation pattern reported `ACTIVE` for
  three that declare `PROPOSED` on line 3 — they also *contain* the word
  `ACTIVE`, in the sentence explaining when a section becomes it. The finding
  was written into a changelog entry before anyone opened the file. **Read the
  header line, not the file** — `grep -m1 'Status:'` — and open the file before
  a status becomes a claim about someone's work.
- 🔴 **A filtered summary is not a measurement — read the raw wire before
  concluding.** Four false or inverted findings in one day (09/09/2026) all came
  from believing a summariser: `/tmp` counted as "outside the sandbox" **twice**,
  in two different instruments, when `workspace-write` includes it by design; a
  `sandboxMode` field that does not exist being sent and **silently discarded**,
  so every measurement described the server's default rather than the setting;
  and a `tool_call` reported as missing that was emitted all along, hidden by a
  summariser that printed only two event types and a `grep` that died of pattern
  complexity and returned empty.
  **Empty output is not absence, and partial output is not the whole.** In every
  one of the four the instrument answered something plausible, and none of them
  failed loudly. What broke the error each time was dumping the unfiltered
  exchange — the protocol trace, the actual bytes sent, the process's own
  stdout — and reading it.

---

## 7. The repository file standard

Every repository in the fleet carries these at the root. Exact names — the
naming is the convention, and tooling depends on it.

| File | Who reads it | Rule |
|---|---|---|
| `README.md` | humans, GitHub | What the project is and how to run it. English. |
| `version.md` | the app, the hooks, the deploy, the release automation | The single authority on the version. **The version is the first semver (`X.Y.Z`) in the file** — a bare string and a markdown document both satisfy that, and both exist in this fleet. **The copy on GitHub is what the Releases on GitHub must match**; the local checkout is not published. See [versioning.md](versioning.md). |
| `CLAUDE.md` | Claude Code | Agent instructions. |
| `AGENTS.md` | other agent tooling (agents.md standard) | **Byte-identical to `CLAUDE.md` below the H1.** Edit one, edit the other. |
| `SECURITY.md` | GitHub, whoever reports a vulnerability | Thin, at the root because that path is what triggers GitHub's *"Report a vulnerability"*. Points at the normative source; does not duplicate it. |
| `CHANGELOG.md` | humans, the commit automation | Newest first. Each `## X.Y.Z - description` heading **is** the commit message. |
| `LICENSE` | GitHub, lawyers | **No extension.** GitHub detects both spellings; extensionless is the fleet's, 41 files to 1. |
| `NOTICE` | GitHub, lawyers | **No extension.** Third-party attribution a license requires. **It must never contradict `LICENSE`** about the license or the copyright holder. |
| `.gitignore` | git | Everything is versioned; **the only exception is a secret.** `.claude/` and `.continue/` are tracked on purpose. |

### The default branch is `master`

**Every repository in this fleet uses `master` as its default branch. Never
`main`.**

This is a house convention, not a technical claim — git works either way. The
value is that it is *uniform*: every script, every runbook, every hook and every
piece of automation can say `origin/master` and be right. The moment half the
fleet says `main`, every one of those has to ask first, and the ones that forget
to ask break quietly.

That is not hypothetical here. `tools/release.sh` resolves the default branch at
runtime **precisely because** the fleet is mixed today, and the fleet-wide sweeps
that built this standard each needed a fallback chain for it. The convention is
what lets that code get simpler later, not more clever.

**A repository created as `main` gets renamed to `master`** — GitHub does the
rename, keeps open pull requests, and leaves a redirect for old links:

```bash
gh api -X POST repos/<owner>/<repo>/branches/main/rename -f new_name=master
```

Then, in every existing clone:

```bash
git branch -m main master
git fetch origin
git branch -u origin/master master
git remote set-head origin -a
```

That last line is not optional, and it is the one people skip. A stale
`origin/HEAD` points at a branch that no longer exists, and tooling that trusts
it fails in a way that reads like a permission problem. Measured on 03/09/2026:
`samirhvbr/samirhvbr` had GitHub's default at `master`, only `master` on the
remote, and a local `origin/HEAD` still pointing at `origin/main` — the fleet
sweep derived the wrong branch from it and its push was refused.

**A deliberate exception is fine when it is written down.** `blue3-intranet-ntheme`
works on `dev`, and says so in its own `version.md`. That is a decision. A repo
sitting on `main` because that is what GitHub defaulted to is not a decision — it
is a default nobody chose.

And these directories:

| Path | Rule |
|---|---|
| `.claude/` | Permission posture, versioned. **It never chooses the model** (below). `settings.local.json` is the machine-local part and stays gitignored. Granting a permission is the owner's act, written with its reason. |
| `.continue/` | The queue (§1), with a mandatory `README.md` (§2). |
| `docs/` | The record (§1), with a curated `README.md` index. `docs/decisions.md` is the ADR log — the strongest convention in the fleet, present in every repo. |
| `.github/` | `CODEOWNERS`, `dependabot.yml`, workflows. |
| `tools/git-hooks/` | Hooks, enabled once per clone with `git config core.hooksPath tools/git-hooks`. |
| `tools/release.sh` | Tags and publishes the Release for the version in `version.md`. Called by `.github/workflows/release.yml`, so the rules have one implementation. |
| `.github/workflows/release.yml` | Publishes the Release on every push that touches `version.md`. |

> A repository may **trim** this set with a reason — SHVIA-SITE is a static
> marketing site and correctly has no `SECURITY.md` or `.continue/`. Trimming
> deliberately is fine. Missing a file by accident is not: SHVIA-DESKTOP shipped
> without a `LICENSE` while its siblings all have the same one, which is an
> oversight, not a decision.


### A comment in `.claude/settings.json` has exactly two legal homes

The file is plain JSON and has no comment syntax, so the fleet documents its
profile with `_comment_*` keys. That works everywhere in the file except one
block, and the exception is not the one you would guess.

`hooks` is the only block whose keys are a **closed enum of event names**
(`PreToolUse`, `PostToolUse`, `SessionStart`, and the rest). Claude Code
validates them against that list, so a `_comment` written there is read as an
event name, matches nothing, and is discarded at startup with a warning.
Everywhere else the schema declares `additionalProperties`, which is exactly why
the `_comment_profile` at the top level and the `_comment` inside `permissions`
— both of them in the skeleton — have never warned.

```
Legal    "_comment_profile": "..."            at the top level
         "permissions": { "_comment": "..." }
Illegal  "hooks": { "_comment": "..." }       read as an event name, dropped
```

**The hook itself keeps working.** Only the stray key is discarded, never the
block around it, and that is what makes this easy to leave in place for months:
the startup warning is the only symptom, and nothing misbehaves.

Measured 05/09/2026 in SHVIA-DESKTOP, the first repository in the fleet to carry
a `hooks` block at all — the `PostToolUse` check of the `impeccable` skill. The
comment moved to a top-level `_comment_hooks` in commit `d362855`; the hook had
been running correctly the whole time. The skeleton has no `hooks` block, so it
was never wrong — this is written down for the repository that adds one.

### Nothing in a repository chooses the model

**The model is the user's choice, made with `/model`, and a subagent inherits it.** A
repository states no opinion:

| Where | What it never carries |
|---|---|
| `.claude/settings.json` | `model`, `fallbackModel`, `availableModels` |
| its `env` block | `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_*_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` |
| `.claude/` | stand-by profiles (`json-opus`, `opus-sonnet`, …) that swap `settings.json` to change the model |
| `.claude/agents/*.md` | a `model:` other than `inherit` |
| any other tool's config | an export of the variables above — `.codex/config.toml` did |

Every one of these existed in this fleet, and every one outlived the model it named:
`opus[1m]` held sessions on the previous Opus while the newer one was in the catalog, the stand-by
profiles pinned Opus 4.8 and Sonnet 4.6, and `CLAUDE_CODE_SUBAGENT_MODEL=opus` sent every
subagent to Opus 5 while the session ran 5.5. A pin in a repository cannot outrank the
organization's managed settings anyway — that layer, which only an Owner edits, is where a
fleet-wide choice belongs if one is ever needed
([ADR-027](decisions.md#adr-027--the-model-is-the-users-choice-and-nothing-in-a-repository-makes-it)).

A fork keeps the agent definitions its upstream wrote (§8, *when the repository is not ours*).

---

## 8. Language

**Rule in force since 03/09/2026: everything in a repository is written in
English (US).** Every document, every edit, **every commit message**, every pull
request, every issue, every code comment, every changelog entry. If it lives in
a repository or in GitHub's interface around one, it is English.

Nothing gets rewritten just because of this rule. An old Portuguese document
stays Portuguese until it is touched again — at which point the edit (or the
whole file, when practical) comes out in English.

**Three carve-outs, and only three:**

| Stays Portuguese | Why |
|---|---|
| **End-user-facing strings** — UI text, transactional email, product copy | That is product i18n for a Brazilian audience, not repository content. A Brazilian user does not read the repo. |
| **The Blue3 internal repositories** — everything in them ([below](#the-blue3-internal-repositories-are-written-in-portuguese)) | Nobody outside the company opens them, and most of what is written into them is operational reasoning where the precision of the sentence is the value ([ADR-020](decisions.md)) |
| **`.continue/` drafts** — the queue, in any repository ([below](#the-queue-is-written-in-the-language-it-is-thought-in)) | It is the author thinking, before the thing exists. It becomes English on the way out, when the work is produced and the document moves to `docs/` ([ADR-022](decisions.md)) |

They are different in kind, and the difference is the whole reason they are three
rows rather than a list. The first is about **what kind of text** — those
strings stay Portuguese in every repository of the fleet. The second is about
**which repository** — all of the text, in a named set. The third is about
**where in the lifecycle** the text is, and it is the only one that is temporary
by construction: every document it covers is meant to leave, and crosses into
English as it does.

Commit messages **used to** be a carve-out of their own. They are not any more
([ADR-014](decisions.md)) — a commit message is repository content, read in
`git log`, in blame, in a PR diff and in the Releases page, by exactly the
audience the English rule exists for.

**Nothing else, and nothing bilingual.** `LICENSE` is the plain English MIT text
— not a PT/EN presentation ([ADR-010](decisions.md)). A `README_br.md` beside a
`README.md` is not the pattern either: a translated pair is two documents that
drift, and BLUE3-INTRANET's pair proves it, at 374 lines against 259.

Code identifiers — class, method, variable and column names — are English, and
always were.

### The queue is written in the language it is thought in

**`.continue/` is written in the language its author thinks in** — Portuguese,
in this fleet. **When the work is produced and the document moves to `docs/`, it
is rewritten in English (US) as part of that move.** The English rule governs the
record; it does not govern the drafting.

The rule exists for a reader who does not read Portuguese and meets our text
first. A queue draft has no such reader yet: it is the author working out what
to build, before the thing exists, and it may never ship — the project can be
dropped, or the design can change three times before a line is written.
Translating it is a cost paid on behalf of a reader who may never have anything
to read, and paid at the worst moment, while the idea is still being formed.

**The boundary is the folder, and that is the whole of it.** `docs/`,
`README.md`, `CHANGELOG.md`, commit messages, pull requests, issues, release
notes and code comments are English (US) exactly as before. **A repository is not
Portuguese because its queue is.**

Nothing is rewritten merely because of this rule, in either direction: an
English `.continue/README.md` that already exists stays English, the same way an
old Portuguese document stays Portuguese under [ADR-005](decisions.md).

This carve-out and [ADR-021](decisions.md) answer the same failure from two
sides. An agent that reads a Portuguese brief in the queue as a rule violation
is one step from "fixing" it, and the fix that suggests itself is moving it to
`docs/` — which turns a plan into a claim that the work exists.

### The Blue3 internal repositories are written in Portuguese

**Everything in them:** documents, commit messages, pull request titles and
bodies, issues, code comments, changelog entries, release notes. This is the
second carve-out, and it is bounded by **who owns the repository on GitHub** —
not by the folder it sits in on disk, and not by its name:

| In the set | Not in the set |
|---|---|
| Every repository under **`github.com/BLUE3-ISP`**, including any created there after 07/09/2026 | **`samirhvbr/meuip`** — named because it lives in the same working folder and is *not* in the set |
| **`samirhvbr/blue3-intranet`** | **`samirhvbr/blue3-rpi`**, **`samirhvbr/blue3-debian-custom-iso`**, **`samirhvbr/blue3-intranet-lscripts`**, **`samirhvbr/blue3-intranet-ntheme`** — moved out of BLUE3-ISP on 23/10/2026, and English (US) from their next version on |
| **`samirhvbr/blue3-ai-login`** | Every other repository of the fleet |
| **`samirhvbr/blue3-atendimento`** — since 29/10/2026, by [ADR-031](decisions.md) | |

```bash
git remote get-url origin    # this is what decides it, in one line
```

**The `samirhvbr` names are matched whole, never as a prefix.**
`samirhvbr/blue3-intranet` is in the set; `samirhvbr/blue3-intranet-lscripts` is
not, however alike the names look. `tools/fleet.sh` matched a prefix until
1.19.4, and the day two `blue3-intranet-*` siblings changed owner it went on
stamping them in Portuguese.

**A change of owner moves the repository across the boundary, and no ADR is
needed for that.** The rule already answers it: the owner is what decides. When
the four repositories above left BLUE3-ISP on 23/10/2026, the owner confirmed
the reading — *they follow the rule into English (US)*. Point `origin` at the new
owner first (`git remote set-url origin …`), then run the echo pass: it swaps
every block that has a Portuguese variant, and its subject says the variant
changed. The text outside the markers — a language note, a commit example in
`version.md` — is the repository's own and is fixed by hand in the same delivery.
Nothing already written is translated because of the move.

**Why they are exempt.** The English rule exists for a reader who does not read
Portuguese and meets our text first. Nobody outside the company opens these
repositories, and much of what is written into them is operational reasoning
rather than documentation — an incident, a queue, a runbook, the sentence
explaining why a migration ran at 02:00. There the precision of the sentence is
the value, and it is written and read by the same people. Translating it costs
more than it returns ([ADR-020](decisions.md)).

**Only the language changes.** `X.Y.Z - description`, the changelog heading that
*is* the subject, no Conventional Commits prefix, one subject per commit, the
bump in the same commit, the agent commits and pushes — all unchanged. Code
identifiers stay English here too. Nothing mechanical changes: `commit-msg`
never checked the language and cannot.

**A repository joins this set by an ADR, never by argument.** "Nobody foreign
reads this one" is true of most of the fleet and is not a reason. The set is a
written boundary; the rule stays a rule precisely because a repository cannot
apply the test to itself. `samirhvbr/blue3-atendimento` joined this way, by
[ADR-031](decisions.md) on 29/10/2026, when the owner decided it before its first
commit.

**These repositories get a different echo block.** A `LANGUAGE-RULE` reading
*"everything here is English (US)"* stamped into one of them contradicts this
section in the repository it governs, so they carry
[`LANGUAGE-RULE-PT`](../templates/echo-blocks/LANGUAGE-RULE-PT.md) instead —
the same rule, in the language of the repository it lands in.

**B3DEV is not part of this**, and it is worth saying because the two are easy
to confuse. Those repositories belong to `tiago-razera`: we are guests there and
the subsection below already answers them. They are Portuguese for the host's
reason, not for ours.

### When the repository is not ours, the upstream's conventions win

Everything above governs **our** repositories. Opening a pull request or an
issue on a repository we do not own is a different act: there we are guests, and
the host's conventions are the ones that hold — the language and the commit
shape both.

The English rule exists so that a collaborator who does not read Portuguese
meets English first. Applied to someone else's repository it produces the
opposite: the one contribution in their log that their own maintainers have to
translate.

**Check before you write. The first signal that answers, wins:**

| # | Signal | How |
|---|---|---|
| 1 | A written instruction — `CONTRIBUTING.md`, a pull request or issue template, a contribution section in the README | `gh api repos/OWNER/REPO/community/profile --jq '.files'` — one call, and it finds them whether they sit at the root or under `.github/` |
| 2 | The last ~20 merged pull requests | `gh pr list --repo OWNER/REPO --state merged --limit 20 --json title,body` |
| 3 | The last ~20 issues | `gh issue list --repo OWNER/REPO --state all --limit 20 --json title` |
| 4 | The commit log | `gh api repos/OWNER/REPO/commits --jq '.[].commit.message'` |

**A written instruction beats observed practice.** If `CONTRIBUTING.md` asks for
English and the log is Portuguese, write English — they asked. Below that line
the **clear majority** of what you read decides, and clear means clear: if you
have to squint at the split, there is no majority.

**When you cannot tell, write English (US).** A private repository, an empty
history, no network, a refused `gh` call and a genuinely mixed log all land in
the same place — the house rule. Unverifiable is not a licence to guess, and
English is the safer wrong answer: it is the language the host is most likely to
read even when it is not the one they write in.

**Their commit convention travels with their language.** `X.Y.Z - description`
is our shape and it is meaningless in a repository with no `version.md` of ours.
There you write their subject line, in their language. Our versioning rules
govern our remotes, not every remote we can push to
([versioning.md](versioning.md#commit-message)).

**What does not bend.** Code identifiers are English, wherever you are. And
nothing in *our* repositories changes because a foreign one is Portuguese — this
subsection is about the text we write **into someone else's repository**, and
about nothing else. See [ADR-019](decisions.md).

---

## 9. A change in behavior ships with the test that fails when the behavior breaks

**A test exists for the next person who touches the code, not to prove the
author right.** It protects an observable result, and it fails when that result
stops holding — never because the code that produces it was rearranged.

> A feature refuses to open a ticket with no category. The test asserts the
> refusal. Tomorrow someone swaps the form component, rewrites the validation or
> makes it faster: the test still passes, because a ticket with no category is
> still refused. The day one gets through, it fails. That is the whole contract.

Five clauses, all normative:

1. **New behavior, and a change in behavior, ship with automated tests
   proportional to the risk**, covering the behavior itself and the failure
   scenarios that matter. Extending an existing test is often enough; a new
   file per feature is not the measure, and a test written to satisfy a
   checklist protects nothing.
2. **A bug fix ships with the test that reproduces the defect** — red before the
   fix, green after — whenever that is feasible. This is where the rule is most
   checkable, and it is what keeps that bug from coming back.
3. **A failing test is never edited to make it green.** First decide which of
   two things happened: a regression, or an intentional change in the
   requirement. Only the second justifies changing the expectation, and the
   commit that changes the requirement is the commit that changes the test —
   the same rule §4 applies to a document made stale by a change. This clause
   is written for agents above all: turning red into green is the shortest path
   to a delivery, and the one path that removes the tripwire.
4. **The delivery includes running the pertinent tests, by a command anyone can
   repeat.** A test written and never run has closed nothing. Each repository
   says how its validation runs on the *Tests run with* line of its
   `CLAUDE.md`; whoever delivers runs it before the commit that reports the work
   done. This stays outside `pre-push` on purpose: the hook asks two questions
   about one line of one file, and a hook that waits four minutes is a hook that
   gets bypassed ([versioning.md](versioning.md#the-hooks)).
5. **Exceptions are proportional and written down.** A wording change or a
   spacing tweak needs no new test. When automation is the wrong tool for a
   change, the changelog entry says why and what was checked instead — a
   sentence, not a form. That keeps the rule from becoming bureaucracy on one
   side and a silent waiver on the other.

What this section is **not**: a testing methodology. Unit against integration,
coverage figures, which framework — those are per-stack decisions and rot in a
month. The rule says what has to be true when a delivery closes, and stops
there. Decided in [ADR-024](decisions.md).

---

## 10. Where this convention applies

Every repository in the fleet, **and only those**. Each one carries a pointer
here in its `.continue/README.md`.

What we write **into** a repository outside the fleet — a pull request, an
issue, a commit on a branch we push there — follows that repository's
conventions instead, not these
([§8](#when-the-repository-is-not-ours-the-upstreams-conventions-win)).

**If you are reading this inside a repository that is not repodocs, this file is
a copy or a link — the source is** `samirhvbr/repodocs/docs/conventions.md`.

Until 02/09/2026 the source was `BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md`.
It moved because a fleet-wide norm living inside one product repository is
invisible to whoever opens another — the exact problem the note at the top of
this file describes. See [ADR-001](decisions.md).
