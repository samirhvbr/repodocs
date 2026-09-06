# Runbook — bootstrapping a repository from this standard

> **Status:** `ACTIVE` · The operational path from an empty repository to one
> that carries the fleet standard.

## 1. Copy the skeleton

```bash
# from inside the new, empty repository
cp -r /path/to/repodocs/templates/skeleton/. .
```

The trailing `/.` copies the dotfiles too — `.claude/`, `.continue/`,
`.github/` and `.gitignore`. Without it you get the visible files only, which
is the mistake that leaves a new repo without its permission posture.

`docs/conventions.md` is deliberately **not** in the skeleton. The norm has one
home ([ADR-001](decisions.md)); the skeleton's `docs/README.md` points back here
instead of carrying a copy that will drift.

The copy also brings
[`docs/repodocs.md`](../templates/skeleton/docs/repodocs.md), which is the map of
this relationship as read from inside the new repository: what arrived by copy,
what arrives by stamp and gets regenerated, what is only ever linked, and what is
lost when one of the files is missing. **It does not repeat this runbook** — it
links back to it for every step below, and for the conformance checks in §7. For
a repository that already has history, its adoption order and merge rules are the
path this runbook's §1 `cp -r` deliberately is not.

## 2. Substitute the placeholders

```bash
grep -rl '<PROJECT_NAME>' . --exclude-dir=.git    # see what you are about to touch
```

| Placeholder | Meaning | Example |
|---|---|---|
| `<PROJECT_NAME>` | Display name, as written in prose | `ShvIA Desktop` |
| `<PROJECT_SLUG>` | Repository name, as on GitHub | `SHVIA-DESKTOP` |
| `<PROJECT_DESCRIPTION>` | One sentence: what it is and who it is for | `Tauri shell for the ShvIA assistant` |
| `<OWNER>` | Copyright holder, full name | `Samir Hanna Verza` |
| `<OWNER_HANDLE>` | GitHub handle, for `CODEOWNERS` | `samirhvbr` |
| `<YEAR>` | Copyright year | `2026` |
| `<CONTACT_EMAIL>` | Security reporting address | `samirhv@me.com` |
| `<ENV_PREFIX>` | Prefix for the hook escape variable | `SHVIA` → `SHVIA_NO_HOOK` |

A one-pass substitution, then read the result — a placeholder replaced inside a
sentence that was written for a different kind of project reads wrong even when
the substitution is correct:

```bash
find . -path ./.git -prune -o -type f -print0 | xargs -0 sed -i \
  -e 's|<PROJECT_NAME>|ShvIA Desktop|g' \
  -e 's|<PROJECT_SLUG>|SHVIA-DESKTOP|g' \
  -e 's|<OWNER>|Samir Hanna Verza|g' \
  -e 's|<OWNER_HANDLE>|samirhvbr|g' \
  -e 's|<YEAR>|2026|g' \
  -e 's|<CONTACT_EMAIL>|samirhv@me.com|g'
grep -rn '<[A-Z_]\+>' . --exclude-dir=.git   # must come back empty
```

`<PROJECT_DESCRIPTION>` and `<ENV_PREFIX>` are left for the hand — the first
because it is prose, the second because it is renamed inside the hooks
(`HOOK_ESCAPE_VAR`, one line in each).

## 3. Adapt what is genuinely per-repo

The skeleton ships defaults, not answers. Three things need a decision:

- **`.claude/settings.json`** — the allow-list. The skeleton grants reading,
  writing and git, and nothing else. Build and test commands for your stack are
  a **grant, made by the owner, written into the file with its reason and how to
  revert it.** Never applied silently.
- **`CLAUDE.md` / `AGENTS.md`** — the bump triggers. The `X`/`Y`/`Z` slots and
  the discipline are the convention; what counts as a `Z` is per-repo. A new
  screen or a new table is a `Z` in a Laravel app; a new runtime capability is
  a `Y` in a desktop shell.
- **`docs/security.md`** — §4 is inherited as written. Adapt the examples to the
  stack; do not delete a subsection because it does not apply *yet*.

## 4. Enable the hooks

Once per clone — including yours, and every collaborator's:

```bash
git config core.hooksPath tools/git-hooks
```

Confirm both directions before you rely on them:

```bash
git commit --allow-empty -m "feat: teste"                      # must be REJECTED
git commit --allow-empty -m "0.1.0 - primeiro commit do repo"  # must be accepted
```

## 5. First commit

`version.md` starts at `0.1.0` in the skeleton (`1.0.0` when the repository is
already the real thing). Write the `CHANGELOG.md` entry first — its H2 **is**
the commit subject:

```bash
git add -A
git commit -m "0.1.0 - estrutura inicial de documentação"
git push
```

## 6. Pre-flight before making a repository public

A private repository accumulates content that assumed privacy. Before flipping
visibility:

- [ ] `git log -p | grep -iE 'password|secret|token|api[_-]?key'` — scan the
      **history**, not just the working tree. A secret removed from HEAD is
      still in every clone.
- [ ] Any secret ever committed has been **rotated**, not merely deleted.
- [ ] No internal hostname, private IP range or infrastructure path that should
      not be public.
- [ ] `LICENSE` is present and `NOTICE` agrees with it about the license and the
      copyright holder.
- [ ] `SECURITY.md` names a reporting address that is actually monitored.
- [ ] Every prescriptive document declares its status; nothing reads as current
      while describing something abandoned.
- [ ] `.continue/` holds no finished item and no half-page detail.
- [ ] `README.md` is in English and describes what the project **is**, not what
      it was going to be.

## 7. Verifying a repository still conforms

```bash
# the twins are identical below the H1
diff <(tail -n +2 CLAUDE.md) <(tail -n +2 AGENTS.md)

# version.md is a bare X.Y.Z
grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' version.md && echo ok

# settings.json parses
python3 -m json.tool .claude/settings.json > /dev/null && echo ok

# the license matches the fleet's
diff LICENSE /path/to/repodocs/LICENSE

# every version in history has a tag and a Release (prints what is missing)
./tools/release.sh --backfill --dry-run
```

If the `diff` on the twins reports anything other than the mirroring comment,
an edit was applied to one file and not the other — that is the known cost of
[ADR-007](decisions.md#adr-007--claudemd-and-agentsmd-are-twin-files-identical-below-the-h1).
