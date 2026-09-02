# templates

> **Status:** `ACTIVE`

[`skeleton/`](skeleton/) is the documentation structure a new repository starts
from. Copying it and substituting the placeholders is the whole bootstrap; the
step-by-step, including what genuinely needs a per-repo decision, is in
[../docs/runbook.md](../docs/runbook.md).

```bash
# from inside the new, empty repository
cp -r /path/to/repodocs/templates/skeleton/. .
```

**The trailing `/.` matters** — it is what brings `.claude/`, `.continue/`,
`.github/` and `.gitignore` along. Without it you get the visible files only,
which is the mistake that leaves a new repository without its permission
posture.

## Placeholders

| Placeholder | Meaning | Example |
|---|---|---|
| `<PROJECT_NAME>` | Display name, as written in prose | `ShvIA Desktop` |
| `<PROJECT_SLUG>` | Repository name, as on GitHub | `SHVIA-DESKTOP` |
| `<PROJECT_DESCRIPTION>` | One sentence: what it is and who it is for | `Tauri shell for the ShvIA assistant` |
| `<OWNER>` | Copyright holder, full name | `Samir Hanna Verza` |
| `<OWNER_HANDLE>` | GitHub handle, for `CODEOWNERS` and clone URLs | `samirhvbr` |
| `<YEAR>` | Copyright year | `2026` |
| `<CONTACT_EMAIL>` | Security reporting address | `samirhv@me.com` |
| `<DATE>` | Today, as `DD/MM/YYYY` | `02/09/2026` |
| `<VERSION>` | The version at the time of writing | `0.1.0` |
| `<ENV_PREFIX>` | Prefix for the hook escape variable | `SHVIA` → `SHVIA_NO_HOOK` |

After substituting, the sweep must come back empty:

```bash
grep -rn '<[A-Z_]\+>' . --exclude-dir=.git
```

`<PROJECT_DESCRIPTION>` and `<ENV_PREFIX>` are left for the hand — the first
because it is prose, the second because it is renamed inside the hooks
(`HOOK_ESCAPE_VAR`, one line in each).

## What the skeleton contains

```
skeleton/
├── README.md              CLAUDE.md   AGENTS.md   (twins, identical below the H1)
├── version.md  (0.1.0)    SECURITY.md CHANGELOG.md
├── LICENSE                NOTICE      .gitignore
├── .github/               CODEOWNERS · dependabot.yml
├── .claude/               settings.json · README.md
├── .continue/             README.md   (the queue's mandatory index)
├── docs/                  README.md · versioning.md · decisions.md
│                          security.md · runbook.md
└── tools/git-hooks/       commit-msg · pre-push
```

## What is deliberately NOT in the skeleton

**[`../docs/conventions.md`](../docs/conventions.md) — the norm itself.** The
skeleton's `docs/README.md` and `CLAUDE.md` link back to this repository
instead of carrying a copy.

That is the point of repodocs, and it is not a convenience: a fleet-wide rule
copied into sixteen repositories is a rule with sixteen versions, fifteen of
them stale. The norm's own §9 says as much, and it says it because the rule
previously lived inside a product repository, where it was invisible to whoever
opened another one ([ADR-001](../docs/decisions.md)).

## Keeping the skeleton honest

The skeleton files are twins of this repository's own root files. When one
changes, check the other — or write down that the divergence is deliberate.

There is one **intended** divergence today: this repository's `version.md` is
`1.0.0` and the skeleton's is `0.1.0`, because a new project has not shipped
anything yet.

The skeleton also ships defaults it expects to be changed, and says so in place:
`.claude/settings.json` grants nothing for any stack, `docs/versioning.md`
leaves the bump triggers as examples, and `docs/security.md` §2 leaves the
threat model to be filled in. A default that is meant to be replaced is marked
with an HTML comment saying so — **if you find one that is not, that is the
defect to fix**, because an unmarked placeholder default is one that ships to
production.
