# Runbook — <PROJECT_NAME>

> **Status:** `ACTIVE` for repository maintenance and release checks (§§5–7).
> Application requirements, installation, configuration and deployment (§§1–4)
> are `PROPOSED` placeholders until the project implements and verifies them.

<!-- Replace sections 1–4 with measured project procedures, then update their
     status above. Sections 5–7 are inherited repository maintenance checks. -->

## 1. Requirements

No application runtime is defined by the skeleton. Record the runtimes and
versions, system packages, accounts and access once the project requires them.

## 2. Repository checkout; application installation pending

These commands prepare the repository for documentation work only:

```bash
git clone git@github.com:<OWNER_HANDLE>/<PROJECT_SLUG>.git
cd <PROJECT_SLUG>
git config core.hooksPath tools/git-hooks   # once per clone — see §5
```

Add application installation and startup commands only after they have been
implemented and verified on a clean environment. State the requirements of each
supported path and how to diagnose a startup failure.

## 3. Configuration

No application configuration or `.env.example` is supplied by the skeleton.
When configuration exists, document each variable, its required or optional
status, and whether it is secret. An `.env.example` must contain only empty or
dummy values ([security.md §5](security.md#5-secrets-and-configuration)).

## 4. Deploy

There is no application deployment procedure yet. Once implemented, record how
a change reaches production, what it restarts, how configuration is reloaded,
and how to recover from a partial failure. Verify the procedure before marking
it active.

## 5. The git hooks

Once per clone — yours, and every collaborator's:

```bash
git config core.hooksPath tools/git-hooks
```

Check the hook directly, without creating commits. Run from the repository
root, outside a merge, with the hook's escape variable unset. `version.md` must
already be in the index; stage it during initial bootstrap. The accepted subject
uses that indexed version, including when a different version is unstaged.

```bash
(
  set -euo pipefail
  hook_version="$(git show :version.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sed -n '1p')"
  test -n "$hook_version"
  hook_other_version=0.0.0
  if [ "$hook_version" = "$hook_other_version" ]; then hook_other_version=0.0.1; fi
  hook_message="$(mktemp)"
  trap 'rm -f "$hook_message"' EXIT

  printf '%s\n' 'feat: a hook validation subject' > "$hook_message"
  if bash tools/git-hooks/commit-msg "$hook_message"; then
    echo 'ERROR: the hook accepted a Conventional Commits prefix' >&2
    exit 1
  fi
  printf '%s - a hook validation subject\n' "$hook_other_version" > "$hook_message"
  if bash tools/git-hooks/commit-msg "$hook_message"; then
    echo 'ERROR: the hook accepted a version absent from the index' >&2
    exit 1
  fi
  printf '%s - a hook validation subject\n' "$hook_version" > "$hook_message"
  bash tools/git-hooks/commit-msg "$hook_message"
  echo 'commit-msg: expected rejection and acceptance checks passed; no commit created'
)
```

Rename `HOOK_ESCAPE_VAR` at the top of each hook to `<ENV_PREFIX>_NO_HOOK`.
Rules: [versioning.md](versioning.md).

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
- [ ] `.continue/` holds no finished item or detailed record of work that already
      exists. Specifications of unbuilt work stay there, at any length.
- [ ] `README.md` is in English and describes what the project **is**, not what
      it was going to be.
- [ ] No placeholder left over from the skeleton:
      `grep -rn '<[A-Z_]\+>' . --exclude-dir=.git`

## 7. Verifying the repository still conforms

```bash
# the twins are identical below the H1
diff <(tail -n +2 CLAUDE.md) <(tail -n +2 AGENTS.md)

# version.md is a bare X.Y.Z
grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$' version.md && echo ok

# settings.json parses
python3 -m json.tool .claude/settings.json > /dev/null && echo ok

# every version in history has a tag and a Release (prints what is missing)
./tools/release.sh --backfill --dry-run
```

If the `diff` on the twins reports anything other than the mirroring comment,
an edit was applied to one file and not the other.
