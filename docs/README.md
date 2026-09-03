# Documentation — repodocs

> **Status:** `ACTIVE`

Index of the project's **stable** documentation. Work in progress lives in
[`../.continue/`](../.continue/) and migrates here when it matures — the trigger
is [conventions.md §1](conventions.md#1-continue-is-the-queue--docs-is-what-has-been-produced).

This index is curated, not exhaustive.

## Pages

| Document | What it answers |
|---|---|
| [conventions.md](conventions.md) | **The norm, and the reason this repository exists.** Queue vs. record vs. history · filenames carry state · the status vocabulary · a document is a release gate · plan-`.md` vs. diagnostic-`.sh` · measurement traps already paid for · the root file standard · the language rule and its two carve-outs. **Single source for the whole fleet.** |
| [versioning.md](versioning.md) | How a version is set and a commit is written. `version.md` is the sole authority and the version is the **first semver in it**; the `X`/`Y`/`Z` criteria; `versão - comentário em português`; why the CHANGELOG heading *is* the commit message; **[tags and Releases](versioning.md#tags-and-releases)** — every version gets both; what the two git hooks check. |
| [decisions.md](decisions.md) | **ADRs 001–009** — the chronological record of what was decided here and why, so it is not re-litigated. |
| [security.md](security.md) | The normative security document. Threat model, the inheritable vulnerability catalogue (§4), secrets and rotation, incident response, the pre-commit checklist. In a conflict with any other document, it wins. |
| [runbook.md](runbook.md) | **From an empty repository to a conforming one.** Copying the skeleton, the placeholder table, what genuinely needs a per-repo decision, enabling the hooks, and the pre-flight checklist before making a repository public. |

## Where a new document goes

| It describes… | It goes to |
|---|---|
| something that already exists — a measurement, a contract, a runbook, an ADR | `docs/` |
| something still to be done, in one line | `.continue/` + a pointer |
| something that happened, with its date and its why | `CHANGELOG.md` |

If a queue item needs half a page, it is in the wrong place: write it here and
leave one line and a pointer in the queue.
