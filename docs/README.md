# Documentation — repodocs

> **Status:** `ACTIVE`

Index of the project's **stable** documentation. Work in progress lives in
[`../.continue/`](../.continue/) and migrates here when the work it describes
exists — the trigger is
[conventions.md §1](conventions.md#1-continue-is-the-queue--docs-is-what-has-been-produced).

This index is curated, not exhaustive.

## Pages

| Document | What it answers |
|---|---|
| [conventions.md](conventions.md) | **The norm, and the reason this repository exists.** Queue vs. record vs. history · filenames carry state · the status vocabulary · a document is a release gate · plan-`.md` vs. diagnostic-`.sh` · measurement traps already paid for · the root file standard · **the default branch is `master`, never `main`** · the language rule and its three carve-outs · **outside the fleet, the upstream's conventions win** · **a change in behavior ships with the test that fails when it breaks**. **Single source for the whole fleet.** |
| [versioning.md](versioning.md) | How a version is set and a commit is written, and **[who commits and when](versioning.md#who-commits-and-when)** — the agent does, nothing is finished until it is committed, one subject per commit, a large delivery split into blocks. `version.md` is the sole authority and the version is the **first semver in it**; the `X`/`Y`/`Z` criteria; `X.Y.Z - description in English`; why the CHANGELOG heading *is* the commit message; **[tags and Releases](versioning.md#tags-and-releases)** — every version gets both; what the two git hooks check. |
| [decisions.md](decisions.md) | **ADRs** — the chronological record of what was decided here and why, so it is not re-litigated. |
| [ci.md](ci.md) | **The fleet's CI machine, `cicd`** — a self-hosted GitHub Actions runner. What it is, the six rules (**every repository may use it, public ones included, since ADR-030**), how a repository joins, the case of a collaborator's repository in another account, and what it does not do. **Carries the internal address, so it is in the pre-flight before repodocs could be public.** The machine's own runbook lives in `shvia-web` and is linked, not copied ([ADR-029](decisions.md#adr-029--the-fleets-ci-machine-is-documented-once-and-its-rule-reaches-every-repository-as-an-echo-block)). |
| [security.md](security.md) | The normative security document. Threat model, the inheritable vulnerability catalogue (§4), secrets and rotation, incident response, the pre-commit checklist. In a conflict with any other document, it wins. |
| [runbook.md](runbook.md) | **From an empty repository to a conforming one.** Copying the skeleton, the placeholder table, what genuinely needs a per-repo decision, enabling the hooks, and the pre-flight checklist before making a repository public. |

## Where a new document goes

| It describes… | It goes to |
|---|---|
| something that already exists — a measurement, a contract, a runbook, an ADR | `docs/` |
| something still to be done — **at any length**, in whatever shape | `.continue/` |
| something that happened, with its date and its why | `CHANGELOG.md` |

**A document leaves `.continue/` when, and only when, the thing it describes
exists.** Length is not an exit condition, and neither is language, age or
untidiness. A 1,300-line brief about something unbuilt is in the only place it
can be — it *is* the specification, and until the thing exists it is the only
place the thing exists. To *produce* a queue item is to make the thing exist,
not to edit, translate or promote the document. **Never empty that folder as
tidying.**

If a queue item needs half a page **to describe something that already exists**,
that is a record that ended up in the queue: write it here and leave one line
and a pointer. That is the whole reach of the rule.
