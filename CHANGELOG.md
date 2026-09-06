# Changelog

Entries in the commit-message format (`version - short description in English`,
see [docs/versioning.md](docs/versioning.md)), newest first. **Each `##` heading is
literally the commit subject** — the entry is written before the commit, so the
sentence that lands in `git log` is one that was weighed rather than improvised
at `git commit` time.

Bodies are narrative: what changed, why, and what was measured. This file is
never rewritten.

## 1.8.3 - the skeleton carries its own map of what came from repodocs

A repository created from the skeleton has always known the rules and never known
their shape. `CLAUDE.md` told it where the norm lives; `docs/README.md` told it the
norm is deliberately not copied. Neither said which of the thirty-odd files in the
new repository arrived from the standard, which of them are mirrors that get
overwritten on the next fleet pass, and which are now simply that repository's own
files to edit. Every one of those questions had an answer, and every answer lived
here, in a repository the new one only links to.

That gap is not theoretical, and the queue records where it lands. The `1.5.1`
sweep found heading variants of an echo block across the fleet — blocks that had
been *edited* in place rather than regenerated, by someone with no way to know the
difference. An echo block edited locally is worse than one left alone: the next
regeneration overwrites the edit silently, and until it does, that repository is
following a rule no other repository has.

`templates/skeleton/docs/repodocs.md` is the answer, and it ships inside every new
repository rather than staying here. It carries the mental map of the relationship
— what travels out of repodocs **by copy** (the skeleton, once, and then it stops
being repodocs' business), what travels **by stamp** (the three echo blocks,
regenerated and never edited), and what **never travels** (`conventions.md`, linked
only, because a rule copied into sixteen repositories is a rule with sixteen
versions) — then the manifest of every file with what is actually lost when it is
missing, an adoption order for a repository that already has history, and the table
of which question is answered upstream rather than locally.

**It repeats none of the bootstrap procedure**, and that restraint is the whole
test of whether this repository believes its own first golden rule. The placeholder
table, the per-repo decisions and the conformance checks stay in `docs/runbook.md`,
which the new page links; a second copy of them would have been exactly the failure
the standard exists to prevent. What the page owns is what had no owner before: the
manifest, the three merge rules for a retrofit, and the regeneration rule.

The `.claude/` row of the manifest names the trap this fleet has already paid for
once — a `cp -r` without the trailing `/.` produces a repository that looks
conforming and has no permission posture. The retrofit section makes the same kind
of failure explicit for an existing repository: never overwrite a file the
repository already had, keep an existing document that already answers the
question, and do not restart the version at `0.1.0` on a repository already at
`2.4.0`.

One intended divergence is created here: the skeleton now has a `docs/` page with
no twin in this repository's own `docs/`. It is correct that it has none — repodocs
does not need a map of its relationship to itself — and `templates/README.md`
records it so the next honesty check does not read it as drift.

## 1.8.2 - the settings comment rule names the one block that rejects it

`.claude/settings.json` is plain JSON with no comment syntax, so the fleet
documents its profile with `_comment_*` keys. The convention was never written
down because it had never failed — and it had never failed because no repository
in the fleet had a `hooks` block.

SHVIA-DESKTOP became the first, with the `PostToolUse` check of the `impeccable`
skill, and the comment placed inside `hooks` was dropped at every startup with
`Unknown hook event "_comment" was ignored`. `hooks` is the only block whose keys
are a closed enum of event names; everywhere else the schema declares
`additionalProperties`, which is why the `_comment_profile` at the top level and
the `_comment` inside `permissions` — both in the skeleton — have never warned.

What made it survive is that nothing broke: the hook ran correctly the whole
time, and only the stray key was discarded. The warning was the entire symptom.
Fixed there in `d362855` by moving the string to a top-level `_comment_hooks`.

Neither `settings.json` here needed a change — this repository and the skeleton
both have no `hooks` block, so both were already correct. §7 gains the rule for
the repository that adds one.

## 1.8.1 - the written-instruction probe reads the community profile, not a guessed path

Running the `1.8.0` procedure against a real upstream found its first step wrong.
It probed `repos/OWNER/REPO/contents/CONTRIBUTING.md`, which is one guess at one
path: `cli/cli` keeps its `CONTRIBUTING.md` under `.github/`, so the probe
returned a raw 404 blob and the check silently reported "no written instruction"
for a repository that has one. A signal that fails closed in the wrong direction
is worse than no signal, because the next step down — observed practice — then
gets treated as authoritative.

`gh api repos/OWNER/REPO/community/profile --jq '.files'` is one call and returns
the contributing guide, the pull request template, the issue template and the
readme with their real URLs, wherever they live. Verified against `cli/cli`
(`.github/`) and `rails/rails` (root).

The `LANGUAGE-RULE` block is untouched: it carries the ordering of the signals,
not the commands, so it did not inherit the defect and does not need a fourth
regeneration.

## 1.8.0 - the norm gains the guest clause: outside the fleet, the upstream's conventions win

`1.3.0` put everything in English (US) — documents, commit messages, pull
requests, issues — and ADR-014 quoted the instruction that produced it: *"todo
commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*. That rule was
written for the fleet, fifty private repositories with one owner, and it never
had to say so because nothing else was in view.

It says so now. Read literally, the rule sends an English pull request into
`tiago-razera`, a repository that works entirely in Portuguese. That is the wrong
output for the right reason: the English rule exists so a collaborator who does
not read Portuguese meets English first, and applied to someone else's repository
it produces the exact opposite — the one contribution in their log that their own
maintainers have to translate. A norm that makes us a worse guest is a norm
applied outside its scope.

[ADR-019](docs/decisions.md) draws the boundary. **The English (US) rule governs
the repositories we own; in a repository we do not own, the host's conventions
govern — the language and the commit shape both.** `conventions.md` §8 gains the
procedure: a written instruction first (`CONTRIBUTING.md`, a template, a
contribution section), then the last ~20 merged pull requests, then the issues,
then the log. A written instruction beats observed practice; below it the clear
majority decides. **When it cannot be determined, the house rule stands: English
(US)** — a private repository, an empty history, no network and a genuinely mixed
log all land in the same place, because unverifiable is not a licence to guess.

The commit shape travels with the language, and it has to: `X.Y.Z - description`
reads as noise in a repository with no `version.md` of ours, and there is no
version there for us to bump. Our versioning rules govern our remotes, not every
remote we can push to.

**It is a scope boundary, not a carve-out**, and that distinction is what keeps
the rest of the norm intact. The carve-outs answer *what kind of text* stays
Portuguese inside our repositories; this answers *whose repository* the text is
going into. The count is still one, and every document that says "one carve-out,
and only one" is still literally true — six files that would otherwise all have
needed rewording. Merging the two ideas would have made the English rule look
negotiable at home, which it is not.

## 1.7.0 - the human gate is a refused push, and the rule that said otherwise leaves the fleet

`1.5.0` said the agent commits and pushes. It never said where a person is still
required, and the gap produced a wrong answer within hours.

SHVIA-WEB carried one line from the COMMITTER era — *"Nada é commitado sem revisão
humana"* — which back then meant "the robot must not publish unreviewed work". Read
next to ADR-016 it says the opposite of ADR-016: if nothing may be committed without
review, an agent cannot commit its own delivery, and the delivery stops in a dirty
tree. Reconciling it, this session proposed *"nothing reaches `master` without human
review"*, reasoning that the repository reviews at merge, and flagged it as a
judgement made on the owner's behalf.

**The owner rejected that reading**, and the correction is the substance of this
version: commits and pushes both happen on **every** delivery, and review is not a
checkpoint the work waits at. The gate is a **refused** push — conflict,
non-fast-forward, protected branch. There the agent stops and says so; it does not
force, does not rewrite history to get past it, and does not invent a merge
resolution it has not verified.

[ADR-018](docs/decisions.md) records it. The gate sits there and nowhere else because
a refused push is the only one of the three moments that is *about someone else's
work* — someone changed the same lines, or a rule says this branch is not yours to
move. A gate on the commit stops the work existing; a gate on a clean push stops it
being visible. Only the third is a decision with another person on the other side,
and that is the one an agent should not take alone.

The `COMMIT-RULE` block gains the clause and is regenerated — the third regeneration
in a day. The phrase *"nada é commitado sem revisão humana"* leaves the fleet, because
under this ADR it is false.

## 1.6.0 - the bump clause gets a written escape hatch, because one repository already had one

`1.5.0` stated the bump as unconditional — *"the version taken from `version.md`
and bumped in the same commit"* — and `1.5.1` stamped that sentence into 147 agent
files. In 49 repositories it was right. In one it was false on arrival.

**SHVIA-WEB has not bumped in the commit since 29/08/2026, on purpose.** Its agent
writes the changelog entry with a `## (versão no merge) - description` placeholder
and the number is stamped at merge by `scripts/versao-no-merge.sh --apply`, read
from the remote. The reason is measured, not stylistic: **four `version.md`
collisions in a single day, between four parallel sessions.** A worktree isolates a
directory, not a number, and that repository has twenty of them live — a shape
nothing else in the fleet has.

So the block sat in that file next to a rule saying the opposite. A session working
there found two instructions governing the same act, could not tell which one won,
and stopped to ask instead of picking one. That is the right outcome and also the
whole diagnosis: **an instruction that needs a human to adjudicate it is not an
instruction.**

[ADR-017](docs/decisions.md) amends ADR-016. **The bump is the one clause a
repository may override, and only in writing** — its own documentation has to state
the alternative and state why. Everything else is unconditional: the changelog entry
first, the `X.Y.Z - description` subject, English (US), no Conventional Commits
prefixes, one subject per commit, nothing reported as finished before it is
committed.

The bump is singled out because it is the only clause whose correctness depends on
the repository's *shape* rather than on the norm. Twenty parallel worktrees make
in-commit bumping collide; one working tree does not. Every other clause is about
how a change is described and when it is recorded, and none of that varies with how
many worktrees a project has. "In writing" is the entire condition, the same
construction [ADR-015](docs/decisions.md) already uses for the default branch: an
undocumented override is not an exception, it is a repository quietly disagreeing
with the norm, and the next session cannot tell those apart.

**This is the first real exercise of the delimited-block design.** ADR-016 argued
for it against per-repo prose on the grounds that a fleet-wide correction should be
one pass rather than an archaeology. The correction arrived a day later, and the
argument holds: one edit here, regenerated everywhere.

The honest cost, recorded because it is a real one: a rule with an escape hatch is
weaker than one without, and this hatch was cut the day after the rule. The
alternative was worse — a block that is provably false in one repository teaches
every reader that the block is approximately true, and an approximately-true
instruction is one nobody stops at.

## 1.5.1 - the COMMIT-RULE pass over the fleet is done, and the ADR-007 twins with it

`1.5.0` decided that the agent commits and shipped the `COMMIT-RULE` block, but
left the pass over the sibling repositories queued, with a warning that it was
the most expensive open item: until it ran, 91 agent files across the fleet still
carried the `PS — Commits: a skill COMMITTER cuida disso` block telling agents
*not* to commit, pointing at a cycle that no longer runs.

It ran the same day. The block is now in **147** `CLAUDE.md`/`AGENTS.md` files —
50 repositories (each with its own bump, commit, push and Release) and 26
worktrees (no bump: the version belongs to the mainline, and repeating one number
across 20 branches manufactures exactly the duplicate the `pre-push` hook exists
to reject). No PS block survives outside the quarantine directory.

Two things the sweep found that a naive replacement would have missed, recorded
because the next fleet pass will meet them again:

- **The PS block had two heading variants** — the Portuguese original in 38 files
  and an English translation, `## PS — Commits: the COMMITTER skill handles them`,
  in the 6 SSHVTERM files. A pattern matching only the first would have left the
  false instruction standing in three repositories.
- **`_quarentena/2026-09-03/` is not inert.** Its copies are full clones pointing
  at the same production remotes as the live repositories — the SHVIA-WEB copy
  was three commits behind the live one — and several sit on a detached HEAD.
  Committing or pushing from there publishes stale state to a live remote. It was
  left out deliberately; 14 files there still carry the old block.

**The ADR-007 twins came with it.** Six repositories — `BLUE3-F1`,
`BLUE3-INTRANET-MOBILE`, `BLUE3-NDRIVE-SERVER`, `BLUE3-SITE-FRONT`,
`BLUE3-WCUP-2026` and `BRASILEIRAO_A_2026` — still used the older shape where
`AGENTS.md` was the real document and `CLAUDE.md` a summary of it (or, in
NDRIVE's case, the reverse, with `AGENTS.md` reduced to a pointer). They are one
document now, byte-identical below the H1, following the shape SHVIA-WEB set at
`2.110.166`.

Merging them was not concatenation. Three of the pairs **contradicted each other
about the commit convention**: `BLUE3-INTRANET-MOBILE` and `BLUE3-F1` had
`AGENTS.md` mandating Conventional Commits (`feat:`, `fix:`) while `CLAUDE.md`
mandated `X.Y.Z - description`, and Conventional Commits is what
[ADR-003](docs/decisions.md) forbids. Every such conflict was resolved toward the
fleet norm, and the same pass corrected the `Mensagem em português` lines that
[ADR-014](docs/decisions.md) had made false — they were sitting in the same file
as a `COMMIT-RULE` block saying English (US).

Every repository touched has its tag and Release: 57 checked, `version.md`
matching the published `Latest` in all of them.

## 1.5.0 - the agent commits again, and nothing is finished until it is committed

For a month the agents in this fleet did not commit. The COMMITTER skill existed
to take that work off them: from 30/07/2026 a `.committer.yml` marker was the
opt-in, a cron cycle read the changelog entry the agent had left behind, built
the `X.Y.Z - description` subject from it, committed and pushed. The rollout put
the marker in 43 repositories and a matching block into 42 `CLAUDE.md`/`AGENTS.md`
files, and that block said it plainly: *"commitar e pushar não é trabalho seu"*.

On 03/09/2026 the owner switched the skill off across the fleet — 35 markers
flipped to `enabled: false`, and the sweep in `~/x/GIT/run.sh` now reports
`no-op: kill-switch` for all 44 repositories it discovers.

**Switching off the automation did not unwrite the delegation.** That is the
defect this version closes. The instruction "do not commit" is still sitting in
42 agent files; the cycle that was supposed to follow it no longer runs. An agent
reading one of those files stops at a dirty working tree that nothing is
watching — a state strictly worse than before the skill existed, because before
it the agent at least knew the commit was its job.

**[ADR-016](docs/decisions.md)** puts it back, and puts back more than was taken.
The old rule was only *how* a commit is written; this one covers *who* writes it
and *when*:

- **The agent commits** — `git commit` and `git push` as the last step of the
  work, with no automation downstream.
- **A delivery is not delivered until it is committed.** No task is reported as
  finished while it sits uncommitted. "Done" means it is in `git log`.
- **One subject per commit.** When the description needs an "and" to be true, it
  is two commits.
- **A large delivery is split into blocks**, grouped by subject, sharing one
  version — because the history is the documentation of *how* the work was done.

The normative text is the new
[`versioning.md` §"Who commits, and when"](docs/versioning.md#who-commits-and-when).
Two passages there had gone stale on the same day and were corrected in this
pass: the "Who creates it" table still listed COMMITTER as an owner of Releases,
and `CHANGELOG.md`'s own header still called itself *"the handoff artefact
between whoever does the work and whoever commits it"* — there is no handoff any
more, the two are the same agent.

**How it reaches the fleet is the part that was designed rather than written.**
The rule ships as `templates/echo-blocks/COMMIT-RULE.md`, a delimited block in
the shape `RELEASES-RULE` already uses in 113 files, and `templates/echo-blocks/`
is new in this version for exactly that purpose. The reasoning is in the ADR: the
COMMITTER rollout is itself the proof that per-repo wording does not survive a
reversal — it put bespoke prose into 42 files, and when the decision behind it
was undone there was no mechanical way to find and replace it. A named,
delimited block can be regenerated in one pass.

**What is done here and what is not.** repodocs carries the block, the golden
rule, the release-gate line in `conventions.md` §4 and the skeleton, so every
repository created from now on is born with the rule. The 42 files in the
existing fleet still carry the false PS block; that pass is queued in
`.continue/README.md` with a warning that it is the most expensive open item,
because until it runs the fleet's agent instructions contradict this repository.

## 1.4.3 - correcting the activation claim in 1.4.2: the hooks are live here

The 1.4.2 entry said *"the hook is not active anywhere yet — no clone in the
fleet has `core.hooksPath` set"*. That was written from a sample of six
repositories and is false: the push that published 1.4.2 was itself checked by
the hook, which printed `pre-push: version 1.4.1 -> 1.4.2 — ok`.

Measured across all 92 clones under `~/x`: **exactly one has `core.hooksPath`
set — `repodocs` itself.** Only two carry `tools/git-hooks` on disk at all
(`repodocs` and `EOP`). So the defect was live in precisely the repository whose
`version.md` is a bare string and therefore passed the broken check anyway, and
latent in the 91 others.

The finding and the fix in 1.4.2 stand unchanged; only the reach claim was
wrong. Corrected in place there as well, because a measured number that is wrong
is the failure mode this repository exists to prevent — history is not
rewritten, so this entry records that the correction happened.

## 1.4.2 - the pre-push hook reads the first semver, like release.sh already did

`tools/git-hooks/pre-push` rejected any `version.md` that was not a bare `X.Y.Z`
string, and said so citing `docs/versioning.md` — the document that says the
opposite. [ADR-012](docs/decisions.md) replaced the bare-string requirement with
the first-semver rule precisely because a third of the fleet was measured to use
the markdown shape, and `tools/release.sh` has implemented that rule since it was
written (`first_semver()`, line 65). Two files, one rule, two readings; the hook
had the wrong one.

**What it would have cost.** Measured on
the fleet today: `shvia-workspace` (`**Versão atual:** \`0.27.17\``) and
`skill-dashproject` (`0.5.4`) both fail the old check and pass the new one, and
so does every BLUE3-ISP repository. Enabling the hooks as documented would have
refused every push from those repos, with an error message rendered unreadable
by `tr -d '[:space:]'` collapsing the whole markdown file into one string.

Fixed in the root hook **and** in `templates/skeleton/tools/git-hooks/pre-push`,
which is the copy every new repository inherits — the same defect was being
minted forward. Both the local read and the `origin/<default>` read now use
`grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1`, byte-for-byte the reading
`release.sh` does, so the duplicate-and-monotonicity checks keep working on both
file shapes.

Also corrected here, under the "stale in the same pass" rule: this file's own
preamble still described the commit format as *"versão - comentário em
português"*, which [ADR-014](docs/decisions.md) superseded on 03/09/2026.

## 1.4.1 - the release workflow fires on the default branch, whatever it is named

Caught by the final sweep of the rollout: 50 of 51 repos had `version.md` equal
to the `Latest` Release. The one that did not was `blue3-intranet-ntheme`, at
`0.1.3` with the Release stuck on `0.1.1`.

**Cause.** `release.yml` listed `branches: [master, main]`. That reads like "the
default branch" and is not: this repo works on `dev`, by written decision
recorded in its own `version.md`. The workflow had **zero runs** since being
installed — it was never going to fire.

**Fix.** The branch filter is gone. The job checks `github.ref_name` against
`github.event.repository.default_branch` instead, which is the same authority the
whole rule already rests on. Verified: the push landed on `dev`, the workflow ran
in 16s, and the Release appeared.

The two versions it had missed (`0.1.2`, `0.1.3`) were backfilled, and the badge
reconciliation moved `Latest` to `0.1.4` on its own — the self-healing behaviour
added in `1.2.3` doing its job unprompted.

**The other 50 repositories keep the older trigger for now.** It is functionally
correct for all of them (every one is on `master` or `main`), so a 50-commit
sweep to change a line that changes no behaviour was not worth the churn. What
this costs is written into [ADR-015](docs/decisions.md): moving a repository to a
non-standard branch is a written decision, and checking that its `release.yml` is
the current one is part of that decision.

## 1.4.0 - the default branch is `master`, never `main`

Census of the 51 fleet repositories, 03/09/2026: **43 on `master`, 7 on `main`,
1 on `dev`**. The seven are not a decision — they are repositories created after
GitHub changed its own default, inheriting whatever the button gave them.

### Why uniformity is the point

Git does not care. Every script, runbook, hook and workflow that wants "the
default branch" does: it either hardcodes one and is wrong for part of the
fleet, or resolves it at runtime and carries a fallback chain forever.
`tools/release.sh` does the latter today **because** the fleet is mixed. This
ADR is what lets those fallbacks be deleted later.

### It already broke something, in this rollout

`samirhvbr/samirhvbr` has GitHub's default at `master` and only `master` on the
remote — but a **stale local `origin/HEAD` still pointing at `origin/main`**. The
fleet sweep read it, derived `main`, pushed `HEAD:main` and was refused. The
failure reads like a permissions problem and is actually a branch name.

Fixed with `git remote set-head origin -a` — the step everyone skips when
renaming a branch, and the one that causes this exact class of failure.

### The rule

`master` is the default branch of every repository here. A repo created as `main`
is renamed with GitHub's own rename (it preserves open pull requests and
redirects old links), and every existing clone is repointed — including
`set-head`.

A different branch is allowed **when it is a written decision**:
`blue3-intranet-ntheme` works on `dev` and says so in its own `version.md`. A
repo sitting on `main` because that is what the button did is not a decision.

### Suggested, not swept

Renaming a default branch is outward-facing: it touches clone instructions, CI
configs that name the branch, and bookmarks to branch URLs. GitHub's rename
covers PRs and redirects; it does not fix a collaborator's clone or a workflow
file that hardcodes `main`. So the seven are **listed for the owner to
schedule**, not renamed on the strength of a convention:

`blue3-debian-custom-iso` · `blue3-ai-login` · `MIGRANDO-ZIMBRA-CARBONIO` ·
`shvia-bench` · `shvia-rota` · `shvia-site` · `shvia-workspace`

Written up in [ADR-015](docs/decisions.md), `docs/conventions.md` §7, the
`CLAUDE.md`/`AGENTS.md` twins and the skeleton.

## 1.3.1 - Agent doc: Releases rule and the English-only language rule

Marked echo of the single source at samirhvbr/repodocs. Two rules land here:

1. The `version.md` of the default branch ON GITHUB is what the GitHub Releases
   show, and a commit that bumps it is not finished until that version has a
   tag, a Release and the `Latest` badge — same push, not "later".
2. Everything in this repository is English (US): documents, commit messages,
   pull requests, issues, code comments. The only carve-out is end-user-facing
   product strings. History is not rewritten.

Delimited by a marker, so re-running replaces instead of duplicating.


## 1.3.0 - everything is English (US), commit messages included

The owner rejected the last language split, and the trigger was a commit this
very rollout had just written across the fleet:

> `1.0.1 - Regra de Releases no doc de agente: bump e Release sao um ato so`

> *"precisamos documentar a regra de que commits tambem, tudo em ingles"*
> *"todo commit em ingles, PR em ingles, issues em ingles, tudo ingles-US"*

### Why the split did not survive

ADR-005 put documents in English but kept commit messages in Portuguese,
reasoning that the commit convention was a separate per-repo rule. That reasoning
ignores where a commit message is actually read: `git log`, `git blame`, the diff
of a pull request, the body of a Release, and the changelog entry it was copied
from. It is exactly the surface the English rule exists for — the first thing a
collaborator or a tool that does not read Portuguese meets.

### The rule now

**Everything in a repository, and in GitHub's interface around it, is English
(US)** — documents, commit messages, PR titles and bodies, issues, code comments,
changelog entries, release notes.

**Exactly one carve-out remains:** end-user-facing strings — UI text,
transactional email, product copy. A Brazilian user does not read the repository.

That takes the carve-out list from three, to two after `LICENSE` fell in
[ADR-010](docs/decisions.md), to **one** here in
[ADR-014](docs/decisions.md).

### What was changed

`docs/conventions.md` §8, `docs/versioning.md` (format and examples),
`docs/README.md`, `README.md`, the `CLAUDE.md`/`AGENTS.md` twins, and the whole
`templates/skeleton/`. ADR-003's language clause is marked superseded rather than
edited away; ADR-005's carve-out list now points here.

### What enforces it, and what does not

`tools/git-hooks/commit-msg` checks the **shape** — `X.Y.Z - description`, no
Conventional Commits prefix, no vague one-word message — and its reject list
gained the English offenders (`cleanup`, `changes`, `tweak`, `stuff`,
`refactor`) next to the Portuguese ones already there.

It does **not** check the language, on purpose. Detecting language mechanically
is guesswork, and a guard that fires on a false positive is a guard that gets
bypassed with `--no-verify` — which disables every other guard with it. The
shape is mechanical; the language is the norm's job.

### History is not rewritten

Portuguese messages already in the fleet's history stay. `git log` will read
bilingual across the 03/09/2026 boundary, which is the same shape ADR-005
already accepted for documents, for the same reason.

## 1.2.4 - Regra de Releases no doc de agente: bump e Release sao um ato so

Eco marcado da norma unica em samirhvbr/repodocs (docs/versioning.md). O
`version.md` da branch padrao NO GITHUB e o que as Releases no GitHub mostram, e
um commit que bumpa o `version.md` nao esta terminado ate aquela versao ter tag,
Release e o badge `Latest`.

Bloco delimitado por marcador: rodar de novo substitui, nao duplica.


## 1.2.3 - o bump e a Release sao um ato so, e o badge Latest obedece ao version.md

Achado do dono, olhando o `sshvterm-desktop`: *"teve um bump para version.md
para 1.2.81 mas o Releases esta em 1.2.80"*.

### O que estava errado

A Release `1.2.81` **existia** — o workflow rodou e criou. O que estava errado
era so o **badge `Latest`**, parado na `1.2.80`. Varredura nos 51: tres repos
com o mesmo sintoma, e nos tres a Release existia. O pior era o `shvia-web`,
com `version.md` em `2.110.162` e badge em `2.16.38`.

### A causa foi minha

O backfill carimbava `--latest` na **ultima versao que aquela rodada conhecia**.
No `sshvterm-desktop` ele comecou lendo `1.2.80`, um push moveu o arquivo para
`1.2.81` no meio, e no fim ele empurrou o badge de volta para `1.2.80`. Correu
contra o proprio workflow — e ganhou a corrida errada.

### Duas correcoes no `release.sh`

1. **`--latest` so vai para a versao que o `version.md` nomeia**, nunca para "a
   ultima que esta rodada tocou".
2. Toda execucao termina **relendo o `version.md` do remoto e movendo o badge**
   se ele tiver derivado. Isso torna qualquer rodada auto-corretiva:

       release.sh: badge Latest movido de 1.2.80 para 1.2.81 (version.md manda)

Entao a pergunta *"este repo esta certo?"* virou um comando que tambem conserta:
`./tools/release.sh`.

### A regra que passou a estar escrita

**O bump e a Release sao um ato so.** Um commit que bumpa o `version.md` nao
esta terminado enquanto aquela versao nao tiver Release **e o badge**. Nao
"depois", nao "quando alguem lembrar" — no mesmo push. Esta em
`docs/versioning.md`, no gate de fechar versao do `docs/conventions.md`, nos
gemeos e no skeleton.

O badge nao e cosmetico: quem olha le como *"esta e a versao corrente"*, e um
badge numa Release velha afirma algo falso sobre o projeto.

### Um erro de operacao que vale registrar

Eu editei o `release.sh` **com ele rodando** no backfill do `shvia-web`. O bash
le o arquivo em pedacos, o deslocamento quebrou a sintaxe no meio da execucao
(`syntax error near unexpected token` na linha 226) e a rodada morreu em
`2.16.71` de 764. Retomada com uma **copia congelada** do script — o backfill e
idempotente, entao ela continuou de onde parou, mas o certo era congelar antes.

## 1.2.2 - o remoto e a autoridade: version.md do GitHub = Releases do GitHub

Correcao do dono, e ela apagou uma ambiguidade que eu tinha deixado em pe:

> *"no github o Releases tem que estar na mesma versao do version.md, e meio
> logico, esquece o local"*

O `release.sh` estava lendo o `version.md` da **arvore local**. Passa a ler do
**`origin/<branch padrao>`** e a taggear aquele commit, caindo para `HEAD` so
quando o ref remoto nao resolve — que e o caso do CI, onde o `HEAD` **e** o
commit pushado. Arquivo local divergente vira uma nota, nao uma Release
diferente.

### Por que isso nao era detalhe

Medido no mesmo dia: o `sshvterm-desktop` tinha `1.3.19` local contra `1.2.80`
no remoto (8 commits nao pushados), e o `shvia-web` tinha `2.110.154` local
contra `2.110.161`. Publicar da arvore local taggearia **commit que o GitHub nao
tem**. O guard anterior (recusar quando a arvore diverge do HEAD) tratava o
sintoma; a regra do dono elimina a pergunta.

### O que isso resolve de graca

O fluxo de PR passa a funcionar sem ninguem lembrar de nada: uma branch em
`1.3.25` **nao publica nada** enquanto e branch; no merge, o push do `version.md`
para a branch padrao dispara o workflow e a Release vira `1.3.25`. O merge e o
evento.

### Tambem nesta versao

- **`sshvterm-desktop`, o unico repo da frota com pipeline amarrado em tag.** As
  17 Releases dele eram de junho, tituladas `ShvTerm v0.5.41`, com **178
  instaladores e 10.184 downloads**. Os titulos foram para o padrao (so o
  numero); **nada foi apagado** e os binarios estao intactos. O `v` da tag ali
  **faz trabalho**: o `main.yml` dispara em `tags: ['v*']` — e por isso o
  proximo passo e o gatilho aceitar as duas formas, nao trocar de forma.
- **O `release.sh` deixou de duplicar Release.** Uma versao conta como publicada
  sob **qualquer um dos dois nomes**: criar uma `0.5.41` pura ao lado da
  `v0.5.41` que ja tem binario nao consertaria nome nenhum — duplicaria a versao
  e a copia sairia **sem os instaladores**. No `sshvterm-desktop` isso muda o
  backfill de 227 para **210 criadas e 17 puladas**.

## 1.2.1 - o censo completo derruba o numero que a 1.2.0 publicou

A `1.2.0` afirmou *"54 repositorios, zero Releases publicadas, e tres tags entre
todos eles"*. **Errado.** Aquele numero saiu de uma varredura parcial — a
caminhada local em `~/x` mais a org BLUE3-ISP — e **perdeu o SSHVTERM-DESKTOP
inteiro**.

### O numero real, do censo dos 52 repos com `version.md`

| | |
|---|---|
| Sem nenhuma Release publicada | **50 de 52** |
| Sem nenhuma tag de versao | **47 de 52** |
| Versoes distintas na frota | **~2.764** |
| EOP + SHVIA-WEB | **1.591 delas — 55% do total** |

E cinco repos **ja fazem isso**, todos com prefixo `v`: `SSHVTERM-DESKTOP` (22
tags e **17 Releases publicadas**, tituladas `ShvTerm v0.5.41`),
`brasileirao-a-2026` (17 tags), `blue3-wcup-2026` (3), `blue3-f1` (1), e o
`docsys_blue3` (19 tags, 18 Releases), que e do Rodrigo e esta fora desta frota.

### A consequencia que agora esta escrita

Mostrado o numero, o dono confirmou a decisao: **tag pura em todos, inclusive
nesses cinco**. A consequencia e real e fica dita de frente no
[ADR-011](docs/decisions.md): o SSHVTERM-DESKTOP vai ter `v0.5.41` com a Release
*"ShvTerm v0.5.41"* **convivendo** com uma `0.5.41` nova — a mesma versao
alcancavel por dois nomes. As tags velhas **nao sao apagadas**: apagar orfanaria
17 Releases que ja existem e que alguem pode ter linkado.

### Um defeito que o censo pegou no `release.sh`

O `--current` taggeava o HEAD com a versao lida da **arvore de trabalho**. Oito
repos da frota estao agora com o `version.md` bumpado e **nao commitado** — o
SHVIA-WORKSPACE esta 14 versoes a frente do ultimo commit. Nesses, o `--current`
teria criado uma tag apontando para um commit que nao contem aquela versao.

Agora ele recusa e explica, e diz que o `--backfill` e seguro ali (ele le o
historico, nao a arvore). Testado nos dois sentidos.

### Outros dois achados do censo, ainda abertos

- **SHVIA-WEB local esta 18 commits atras do origin** (local `2.110.154`, origin
  `2.110.161`). Backfill a partir do checkout velho perderia 8 versoes.
- **SHVIA-OLLAMA tem `version.md` nao rastreado pelo git** (`1.2.0`), enquanto a
  ultima versao commitada e `1.1.1`.

Ambos estao na fila em [.continue/README.md](.continue/README.md).

### Por que isto virou entrada propria em vez de conserto silencioso

O CHANGELOG nao e reescrito — e a regra da casa, e ela vale principalmente
quando o que esta escrito e o **erro**. A `1.2.0` fica como esta; esta entrada
diz o que estava errado e o ADR-011 ganhou o aviso apontando para ca. E a
terceira vez seguida que medir contrariou o que este repositorio tinha escrito.

## 1.2.0 - toda versao vira tag e Release, e a regra do version.md sai do papel

O quadro **Releases** do GitHub estava vazio em **todos os 54 repositorios** da
frota, e a causa nao era descuido: o GitHub nunca deduz versao de mensagem de
commit. Um repo com mil commits `2.110.161 - ...` continua dizendo *"No releases
published"*, e `git diff 2.110.160..2.110.161` falha porque **nenhum dos dois
nomes existe como ref**.

### O que foi medido antes de escrever qualquer regra

| Repo | commits | versoes distintas | tags | Releases |
|---|---|---|---|---|
| SHVIA-WEB | 1085 | 756 | 0 | 0 |
| EOP | 840 | 827 | 0 | 0 |
| SHVIA-DESKTOP | 1035 | 98 | 1 | 0 |
| BLUE3-INTRANET | 982 | 150 | 0 | 0 |
| SSHVTERM-WEB | 135 | 75 | 0 | 0 |

Tres tags em 54 repositorios, e zero Releases. Dois repos ja carregavam a divida
**por escrito** no proprio `version.md`: o `blue3-f1` diz *"Ao publicar, taggear
`v0.3.0`"* e o `brasileirao-a-2026` diz *"⚠️ Sem tag `v0.16.0` no git"*.

### A regra que este repositorio publicou errada

O `docs/versioning.md` e o ADR-002 afirmavam que o `version.md` e *"uma string
`X.Y.Z` pura e nada mais"*. **Falso para um terco da frota.** Nove repos do
BLUE3-ISP e o proprio skill-COMMITTER tem um `version.md` que e um documento
markdown inteiro, abrindo com `**Versao atual:** \`0.17.1\``; o
`blue3-intranet-mobile` tem duas linhas (`2.1.9` e `api_min: 0.1.0`).

Esses repos ja documentavam a regra de verdade — *"extrai o primeiro numero
semver encontrado aqui"* — e o `config/app.php` deles ja implementava com
`preg_match('/\d+\.\d+\.\d+/')`. **A versao e o primeiro semver do arquivo**
([ADR-012](docs/decisions.md)), e o ADR-002 fica emendado, nao apagado.

E a segunda vez que uma norma daqui foi contrariada pela frota — a primeira foi o
`LICENSE` bilingue custando o selo MIT (`1.0.1`). As duas apareceram medindo, nao
relendo.

### O que passou a existir

- **`tools/release.sh`** — a implementacao unica: `--current`, `--backfill`,
  `--dry-run`. Idempotente e retomavel por construcao (pula o que ja existe),
  com throttle e parada limpa quando o orcamento de API baixa.
- **`.github/workflows/release.yml`** — dispara a cada push que toca o
  `version.md` e **chama o script**, em vez de reimplementar as regras: duas
  copias de uma regra e como uma regra passa a ter duas versoes, uma errada.
- **ADR-011** (tag e Release por versao), **ADR-012** (primeiro semver),
  **ADR-013** (workflow de release nao e workflow de CI — o ADR-009 fica
  estreitado para proibir so build/teste, com o motivo: CI vermelha em repo de
  documentacao ensina a ignorar CI, e este workflow e silencioso no caso normal).

### A tag nao leva `v`

Decisao do dono. Diverge das tres tags que a frota ja tem (`v0.15.0` e uma na
SHVIA-DESKTOP), que **ficam como historico**; o que sera corrigido sao os dois
`version.md` cujo texto ainda manda usar `v` — documento contradizendo o artefato
e o defeito, nao a tag velha.

### Medido neste repo

Backfill rodado: `1.0.0` → `b5bc824`, `1.0.1` → `e8131fe`, `1.1.0` → `654c999`,
com as notas vindas da secao real do CHANGELOG (a extracao foi corrigida para
parar so num heading do mesmo nivel ou acima — na primeira versao ela cortava a
`1.0.0` no primeiro `###` e perdia 78 das 83 linhas). Re-execucao: zero criadas,
tres puladas. E `git diff 1.0.1..1.1.0` finalmente responde — 16 arquivos.

### O que falta

O rollout nos outros 53 repositorios, com o backfill completo (~2.000-3.000
Releases) sob dry-run lido repo a repo, e o passo equivalente no
**skill-COMMITTER**. Esta na fila em [.continue/README.md](.continue/README.md).

## 1.1.0 - nada bilingue: o LICENSE passa a ser o MIT em ingles puro

Resposta do dono a medicao da `1.0.1`: *"nao, nada bilingue, so ingles, license
e etc so ingles"*. A pergunta que estava na fila saiu respondida.

**O que mudou.** O `LICENSE` deixa de ser PT-depois-EN e passa a ser o texto MIT
em ingles, **byte-identico ao canonico** — o mesmo do `skill-LOOP`, que era o
controle da medicao e que o GitHub detecta como `MIT License`. O
`templates/skeleton/LICENSE` acompanha, com `<YEAR>`/`<OWNER>`.

**O que isso custa, dito de frente.** O `LICENSE` deste repo **nao e mais
byte-identico aos catorze da frota** — ele e byte-identico ao MIT canonico. A
divergencia esta na direcao certa e fecha substituindo os outros, nao revertendo
aqui. Entrou na fila junto com o retrofit da norma.

**A regra de idioma encolheu de tres excecoes para duas.** Ficam em portugues
so a **mensagem de commit** e as **strings voltadas ao usuario final**. O
`LICENSE` saiu da lista, e o par `README.md`/`README_br.md` fica explicitamente
recusado pelo mesmo motivo que uma norma copiada: dois documentos dizendo a
mesma coisa divergem, e um deles fica errado em silencio — o par do
BLUE3-INTRANET esta em 374 linhas contra 259.

**Onde ficou registrado.** [ADR-010](docs/decisions.md) e a decisao nova;
supera a clausula bilingue do ADR-006 (que mantem o resto: nome sem extensao,
MIT, titular, e a regra de o NOTICE nunca contradizer o LICENSE) e revisa a
lista de excecoes do ADR-005. A norma em `docs/conventions.md` §8, os gemeos
`CLAUDE.md`/`AGENTS.md`, os dois `README.md`, os dois `versioning.md` e o
`docs/README.md` foram corrigidos na mesma passada — documento que envelhece em
silencio e pior que documento ausente.

**A fila perdeu uma linha.** O item *"vale o LICENSE bilingue?"* foi **apagado**
de `.continue/README.md`, nao marcado como feito: item concluido sai da fila, e
o registro permanente e este arquivo. Bump **Y** porque houve ADR novo.

## 1.0.1 - o LICENSE bilingue custa o selo MIT do GitHub, medido

Um push é o único jeito de medir o que o GitHub faz com um `LICENSE`, e a
medição contradisse a expectativa.

**O que foi medido.** Depois do push da `1.0.0`, `gh repo view` devolveu
`licenseInfo: Other` — não `MIT License`. O mesmo vale para SHVIA-WEB,
SHVIA-SITE e BLUE3-AI-LOGIN, os três que carregam o mesmo texto bilíngue.
Controle: `skill-LOOP`, que carrega o MIT puro em inglês, é detectado como
`MIT License`.

**Por que.** O detector do GitHub compara o arquivo inteiro com um template de
licença. A metade em português derruba a similaridade abaixo do limiar dele. A
licença **é** MIT nos dois casos — o que se perde é o selo na barra lateral e a
detectabilidade via API.

**O que mudou aqui.** Nada no LICENSE: a escolha do bilíngue foi deliberada e
segue valendo. O que mudou é que o custo dela está medido em vez de suposto —
[ADR-006](docs/decisions.md) ganhou a seção do custo, e a decisão de manter ou
inverter entrou na fila em [.continue/README.md §3](.continue/README.md) como
chamada do dono. A inversão, se vier, espelha o par `README.md`/`README_br.md`
que a frota já usa.

**Também confirmado no mesmo push:** o `SECURITY.md` na raiz funcionou — o
`securityPolicyUrl` do repositório passou a existir.

## 1.0.0 - estrutura inicial de documentação do padrão da frota

The first real content of `repodocs`, which until now was one commit and an
11-byte `README.md`. GitHub's own description of it — *"Documentation for new
repository"* — already said what it was for; this release makes it true.

### What this settles

The standard existed, but only as a pattern to be inferred by opening sixteen
repositories and noticing what they had in common. The measurement:

| Convention | Evidence across the fleet |
|---|---|
| `LICENSE`, no extension | 41 files against **1** `LICENSE.md` |
| `NOTICE`, no extension | 11 files, zero `NOTICE.md` |
| `version.md`, lowercase, bare `X.Y.Z` | 63 files against 1 `VERSION` |
| MIT bilingual PT/EN, `Copyright (c) 2026 Samir Hanna Verza` | byte-identical in 14 repositories |
| Commit `versão - comentário em português` | normative in EOP, SHVIA-DESKTOP, SHVIA-SITE, SHVIA-WEB, BLUE3-INTRANET |
| `CLAUDE.md` + `AGENTS.md` identical below the H1 | EOP and SHVIA-DESKTOP (BLUE3-INTRANET symlinks; SHVIA-WEB diverged on purpose) |

An inferred standard is a standard that drifts. It is now written once, in
English, at [docs/conventions.md](docs/conventions.md).

### The move that mattered

`BLUE3-INTRANET/docs/CONVENCAO-DOCUMENTACAO.md` (157 lines, written 29/08/2026)
already declared itself *"fonte única, vale para todos os repos da frota"* — and
its own §7 admitted the problem: the source of a fleet-wide norm was a path
inside one product repository. **That is the exact failure the document was
written to prevent**, applied to itself: a rule that lives inside one repo is
invisible to whoever opens another.

It moved here, translated, extended with what it lacked (the root-file standard,
the status vocabulary, the language rule and its carve-outs) — [ADR-001](docs/decisions.md).
The INTRANET copy has **not** been touched yet, so two copies exist and this one
is the source; retrofitting the pointer is a separate, explicit pass.

### Two contradictions settled rather than copied

Both were found while measuring, and both were live:

- **`SHVIA-WEB`** — its `LICENSE` says MIT under `Copyright (c) 2026 Samir Hanna
  Verza`, while its `NOTICE` says *"Copyright (c) Blue3. Proprietary software;
  see LICENSE."* Those cannot both be true. This repository's `NOTICE` agrees
  with its `LICENSE`, and [ADR-006](docs/decisions.md) makes that a rule.
- **`BLUE3-INTRANET`** — its `README.md` states *"the old `version.md` was
  removed in favour of this env var"* while `version.md` is still present and
  its own `CLAUDE.md` calls it the source of truth with the env var as fallback.
  [ADR-002](docs/decisions.md) makes `version.md` the sole authority and forbids
  a document from claiming otherwise. Two documents disagreeing about one number
  is how a wrong deploy gets signed off.

### What was created

- **Root:** `README.md` (rewritten), `version.md` (`1.0.0`), the
  `CLAUDE.md`/`AGENTS.md` twins, `SECURITY.md`, this file, `LICENSE` (copied
  byte-for-byte from the fleet's), `NOTICE`, `.gitignore`.
- **`docs/`:** `conventions.md` (the norm), `versioning.md`, `decisions.md`
  (ADR-001…009), `security.md` (English successor to `SECURITY_GUIDELINES.md`
  v1.1), `runbook.md`, `README.md` (index).
- **`.claude/`:** the fleet Opus profile with a 17-rule deny-list, and a
  `README.md` explaining why the deny-list beats the allow-list.
- **`.continue/`:** the queue, with the `README.md` that §2 of the norm makes
  mandatory.
- **`tools/git-hooks/`:** `commit-msg` and `pre-push`, on the EOP topology.
- **`templates/skeleton/`:** the placeholder copy of the whole set, so a new
  repository is `cp -r` plus one substitution pass.
- **`.github/`:** `CODEOWNERS` and `dependabot.yml`. Deliberately no workflow —
  [ADR-009](docs/decisions.md): a red CI on a documentation repository teaches
  people to ignore CI.

### Measured

The hooks were exercised in both directions before shipping: `feat: teste`
rejected, `1.0.0 - <comentário>` accepted, a duplicate version against
`origin/master` rejected, `REPODOCS_NO_HOOK=1` bypassing both, and an
unreachable remote degrading to a warning rather than a refusal. `LICENSE` is
byte-identical to `SHVIA-WEB/LICENSE`; the twins diff clean below the H1.

### What is left

The queue is [.continue/README.md](.continue/README.md). The open item is not
work in this repository — it is the retrofit pass into the sibling repositories,
which is the owner's call to schedule.
