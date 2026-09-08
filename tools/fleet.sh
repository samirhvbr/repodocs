#!/usr/bin/env bash
# fleet.sh — the standard's one instrument for reaching the repositories that
# already exist: install the hooks, stamp the echo blocks, report conformance.
#
#   ./tools/fleet.sh hooks           dry run — classify, change nothing
#   ./tools/fleet.sh hooks --apply   write the hooks and release.sh, enable,
#                                    bump, commit, push
#   ./tools/fleet.sh echo --apply    regenerate the four marked echo blocks in
#                                    CLAUDE.md and AGENTS.md
#   ./tools/fleet.sh check           read-only conformance report
#
# Why one script with three modes and not three scripts: the hard part is not
# writing a file, it is deciding **which repositories** may be written to — the
# owner on `origin`, the language of the repository, the exclusions that are
# written down, the working tree that is mid-edit. That classification is the
# same for all three, and a second copy of it is the failure this standard
# exists to prevent.
#
# What it refuses to do is as important as what it does. It never touches a
# repository we do not own, never overwrites a file a repository wrote for
# itself, never installs where the history follows another convention, never
# commits a file the working tree is already mid-edit on, and never forces a
# push.
#
# Norm: docs/versioning.md · docs/conventions.md · procedure: docs/runbook.md
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPODOCS="$(dirname "$SELF_DIR")"
HOOK_SRC="$REPODOCS/templates/skeleton/tools/git-hooks"
TOOL_SRC="$REPODOCS/templates/skeleton/tools"
ECHO_SRC="$REPODOCS/templates/echo-blocks"

# The blocks, in the order a repository that has none of them should receive.
ECHO_BLOCKS="QUEUE-RULE RELEASES-RULE LANGUAGE-RULE COMMIT-RULE"

MODE=""
ROOT="${HOME}/x"
APPLY=0
PUSH=1
FILTER=""
RELEASES=0

usage() {
  cat <<USAGE
usage: tools/fleet.sh <hooks|echo|check> [options]

  hooks    install/regenerate tools/git-hooks/* and tools/release.sh, and turn
           the hooks on with core.hooksPath
  echo     regenerate the marked echo blocks in CLAUDE.md and AGENTS.md
           ($ECHO_BLOCKS), choosing the -PT variant by the owner on origin
  check    read-only conformance report; writes nothing, anywhere

options:
  --apply            actually write (hooks/echo only; without it, a dry run)
  --no-push          commit but do not push — a refused push is a human's call
  --root DIR         where the fleet lives (default: \$HOME/x)
  --only SUBSTRING   restrict to repositories whose path contains SUBSTRING
  --releases         check only: ask GitHub whether version.md has a Release
                     (one API call per repository, so it is off by default)

In hooks and echo, each selected repository gets ONE commit: the files, the
version bump and the changelog entry, in the language that repository is
written in. The commit goes through the hook it installs.
USAGE
}

[ $# -gt 0 ] || { usage >&2; exit 2; }
case "$1" in
  hooks|echo|check) MODE="$1"; shift ;;
  -h|--help) usage; exit 0 ;;
  *) echo "fleet: unknown mode '$1'" >&2; usage >&2; exit 2 ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --no-push) PUSH=0 ;;
    --root) ROOT="$2"; shift ;;
    --only) FILTER="$2"; shift ;;
    --releases) RELEASES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "fleet: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[ "$MODE" = check ] && APPLY=0

# --------------------------------------------------------------- the rules ---

# The owners whose repositories are ours. Anything else is a repository we are
# guests in, where the host's conventions win (ADR-019) — including our own
# forks of upstream projects, which keep the upstream's commit shape.
# Overridable only so the test fixture can stand up throwaway repositories with
# a fake owner; in normal use it is these two.
FLEET_OWNERS="${FLEET_OWNERS:-samirhvbr BLUE3-ISP}"

# Repositories excluded by name, each for a written reason. This is the list
# that keeps the script from being wrong in a way no heuristic can catch.
excluded_reason() {   # $1 = remote url
  case "$1" in
    *github.com[:/]samirhvbr/shvia-web*)
      printf 'written bump override — the version is stamped at merge, so its subjects carry a placeholder this hook refuses by design (ADR-017)'
      return 0 ;;
  esac
  return 1
}

# The repositories written in Portuguese: the boundary is the owner on GitHub,
# not the folder and not the name (ADR-020).
pt_repository() {   # $1 = remote url
  case "$1" in
    *github.com[:/]BLUE3-ISP/*) return 0 ;;
    *github.com[:/]samirhvbr/blue3-intranet*) return 0 ;;
    *github.com[:/]samirhvbr/blue3-ai-login*) return 0 ;;
  esac
  return 1
}

owner_of() {        # $1 = remote url
  printf '%s' "$1" | sed -E 's#^(git@|https://|ssh://git@)##; s#^github\.com[:/]##; s#/.*$##'
}

slug_of() {         # $1 = remote url  ->  owner/name
  printf '%s' "$1" | sed -E 's#^(git@|https://|ssh://git@)##; s#^github\.com[:/]##; s#\.git$##; s#/$##'
}

first_semver() {    # $1 = file
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$1" 2>/dev/null | head -n 1 || true
}

bump_z() {          # $1 = X.Y.Z
  local x y z
  IFS=. read -r x y z <<<"$1"
  printf '%s.%s.%s' "$x" "$y" "$((z + 1))"
}

# The escape variable a repository already declares is preserved: it is named in
# that repository's own documentation, and renaming it here would break a
# sentence somewhere else.
escape_var_of() {   # $1 = existing hook file (may not exist)
  local v=""
  [ -f "$1" ] && v="$(sed -n 's/^HOOK_ESCAPE_VAR="\([A-Z0-9_]*\)".*/\1/p' "$1" | head -n 1)"
  if [ -n "$v" ] && [ "$v" != "PROJECT_NO_HOOK" ]; then
    printf '%s' "$v"
  else
    printf 'REPODOCS_NO_HOOK'
  fi
}

write_hook() {      # $1 = source, $2 = destination, $3 = escape var
  sed "s/^HOOK_ESCAPE_VAR=\"PROJECT_NO_HOOK\"/HOOK_ESCAPE_VAR=\"$3\"/" "$1" > "$2"
  chmod +x "$2"
}

# A file this standard generates carries a provenance marker. A copy without one
# is the repository's own — EOP's commit-msg is the case this protects — and is
# never overwritten. A copy generated here before the marker existed is
# recognised by what only a generated copy has.
generated_here() {  # $1 = path, $2 = marker
  [ -f "$1" ] || return 0
  grep -q "$2" "$1" && return 0
  case "$2" in
    'repodocs:hook')
      grep -q '^HOOK_ESCAPE_VAR=' "$1" && grep -qE 'commit-msg: REJECTED|pre-push: REJECTED' "$1" && return 0 ;;
    'repodocs:tool')
      grep -q 'release.sh:' "$1" && return 0 ;;
  esac
  return 1
}


# A repository whose .gitignore covers a file the standard tracks cannot be
# written to by a pass: `git add` refuses the path, and refusing it is right —
# the divergence is the .gitignore, not the add. Golden rule 8 says everything
# is versioned and a new exception needs an ADR, so this is a finding about that
# repository and never something to force with `git add -f`.
ignored_standard_files() {   # $1 = repo, $2... = paths — every ignored one
  local repo="$1"; shift
  local out="" f
  for f in "$@"; do
    git -C "$repo" check-ignore -q "$f" 2>/dev/null && out="$out $f"
  done
  printf '%s' "$out"
}

# The subset that actually breaks a pass. `git add` refuses an ignored path only
# when it is **untracked**: a file already in the index goes in regardless of
# what .gitignore says about it. Measured the hard way — a pass over fifty
# repositories died on the first `CHANGELOG.md` it had just created in a
# repository that ignores that name.
blocking_ignored_files() {   # $1 = repo, $2... = paths the mode would write
  local repo="$1"; shift
  local out="" f
  for f in "$@"; do
    git -C "$repo" check-ignore -q "$f" 2>/dev/null || continue
    [ -n "$(git -C "$repo" ls-files -- "$f" 2>/dev/null)" ] && continue
    out="$out $f"
  done
  printf '%s' "$out"
}


# Where the first semver sits decides whether this file can be bumped by
# substitution at all. A `version.md` that declares the version on its own line
# — "**Versão atual:** `0.1.9`", or a bare "0.1.9" — is safe: replacing the first
# occurrence moves the declaration. A file whose first semver is a **changelog
# heading** is not: replacing it renames an entry that already happened instead
# of adding a new one.
#
# 🔴 Measured 08/09/2026 in KIDS/KIDS-PAVIO. Eight consecutive sweeps — three of
# them before this script existed — walked the same entry from `## 0.4.0 - três
# níveis de dificuldade e refino visual` to `## 0.4.8 - …`, renumbering it each
# time. That repository now has one changelog entry, describing work from 0.4.0,
# labelled with the current version, and no record of the eight deliveries in
# between. Nothing was lost from `git log`; the changelog was.
version_bump_is_safe() {   # $1 = repo
  local f="$1/version.md" line
  [ -f "$f" ] || return 1
  line="$(grep -m1 -nE '[0-9]+\.[0-9]+\.[0-9]+' "$f" | cut -d: -f2-)"
  case "$line" in
    '#'*) return 1 ;;      # the first semver is a heading: an entry, not a declaration
  esac
  return 0
}

# ------------------------------------------------------------- echo blocks ---

block_source() {    # $1 = block name, $2 = remote url
  local pt="$ECHO_SRC/$1-PT.md"
  if pt_repository "$2" && [ -f "$pt" ]; then printf '%s' "$pt"
  else printf '%s' "$ECHO_SRC/$1.md"; fi
}

# Replace everything between the markers, or insert the block if the markers are
# not there. Replacing between markers is what makes a heading edited in place
# harmless: the whole block is rewritten, heading included.
stamp_block() {     # $1 = file, $2 = block name, $3 = block source
  local f="$1" name="$2" blk="$3" tmp
  tmp="$(mktemp)"
  if grep -q "<!-- $name:repodocs -->" "$f"; then
    awk -v blk="$blk" -v name="$name" '
      BEGIN { s = "<!-- " name ":repodocs -->"; e = "<!-- /" name " -->" }
      $0 == s { skip = 1; while ((getline l < blk) > 0) print l; close(blk); next }
      skip && $0 == e { skip = 0; next }
      skip { next }
      { print }
    ' "$f" > "$tmp"
  else
    # Keep the blocks together: insert before the first one already present,
    # and only fall back to the end of the file when there is none.
    local anchor=""
    local b
    for b in $ECHO_BLOCKS; do
      if grep -q "<!-- $b:repodocs -->" "$f"; then anchor="<!-- $b:repodocs -->"; break; fi
    done
    awk -v blk="$blk" -v anchor="$anchor" '
      anchor != "" && $0 == anchor && !done { while ((getline l < blk) > 0) print l; close(blk); print ""; done = 1 }
      { print }
      END { if (!done) { print ""; while ((getline l < blk) > 0) print l } }
    ' "$f" > "$tmp"
  fi
  mv "$tmp" "$f"
}

# ------------------------------------------------------------- changelog -----

write_changelog_header() {   # $1 = file, $2 = remote url
  if pt_repository "$2"; then
    cat > "$1" <<'PTHEAD'
# Changelog

Entradas no formato da mensagem de commit (`versão - descrição curta em
português`), mais recente no topo. **Cada cabeçalho `##` é literalmente o
assunto do commit** — a entrada é escrita *antes* do commit, para que a frase
que cai no `git log` seja uma frase pesada e não improvisada na hora.

Corpos são narrativos: o que mudou, por quê e o que foi medido. Este arquivo
não se reescreve.

> **O registro começa aqui.** Este arquivo nasceu depois do repositório: as
> versões anteriores estão no `git log` e não foram retroalimentadas, porque
> reconstruí-las agora produziria uma história plausível, não uma verdadeira.

PTHEAD
  else
    cat > "$1" <<'ENHEAD'
# Changelog

Entries in the commit-message format (`version - short description in English`),
newest first. **Each `##` heading is literally the commit subject** — the entry
is written *before* the commit, so the sentence that lands in `git log` is one
that was weighed rather than improvised at `git commit` time.

Bodies are narrative: what changed, why, and what was measured. This file is
never rewritten.

> **The record starts here.** This file was created after the repository was:
> earlier versions are in `git log` and are deliberately not back-filled, because
> reconstructing them now would produce a plausible history rather than a true
> one.

ENHEAD
  fi
}

prepend_changelog() {  # $1 = file, $2 = entry file
  local tmp; tmp="$(mktemp)"
  awk -v entry="$2" '
    BEGIN { done = 0 }
    /^## / && !done { while ((getline line < entry) > 0) print line; print ""; done = 1 }
    { print }
    END { if (!done) { print ""; while ((getline line < entry) > 0) print line } }
  ' "$1" > "$tmp"
  mv "$tmp" "$1"
}

# --------------------------------------------------------------- discovery ---

declare -a OURS=() FORKS=() SKIPPED=()

while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  [ -n "$FILTER" ] && case "$repo" in *"$FILTER"*) ;; *) continue ;; esac
  [ "$(cd "$repo" && pwd)" = "$REPODOCS" ] && { SKIPPED+=("$repo|the source — it is where these files come from"); continue; }

  # The CONFIGURED url, not the resolved one: `git remote get-url` applies any
  # url.<base>.insteadOf rewrite, and the question here is which repository this
  # is, not which transport git will use to reach it.
  remote="$(git -C "$repo" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$remote" ] || remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  [ -n "$remote" ] || { SKIPPED+=("$repo|no origin remote"); continue; }

  owner="$(owner_of "$remote")"
  case " $FLEET_OWNERS " in
    *" $owner "*) ;;
    *) SKIPPED+=("$repo|not ours — owner is $owner, the host's conventions win"); continue ;;
  esac

  # Does this repository write our subjects *now*? A fork we own but that tracks
  # an upstream does not. The window is the last 5 non-merge subjects, and it is
  # short on purpose: at twenty it reaches back past 03/09/2026, when the format
  # became universal, and reads six fleet repositories' own pre-rule history as
  # evidence against them.
  total="$(git -C "$repo" log --no-merges --format='%s' -5 2>/dev/null | grep -c . || true)"
  [ "${total:-0}" -gt 0 ] || { SKIPPED+=("$repo|no history to read"); continue; }
  mine="$(git -C "$repo" log --no-merges --format='%s' -5 2>/dev/null | grep -cE '^[0-9]+\.[0-9]+\.[0-9]+ - ' || true)"
  if [ "$((mine * 2))" -lt "$total" ]; then
    # Ours, and not writing our subjects: a fork of somebody else's project that
    # we own and modify. It is not a repository to install hooks into — they
    # would refuse every upstream commit it is about to receive — but it is very
    # much a repository this standard has something to say about, and until
    # 1.13.0 `check` did not even list it. Fourteen of them.
    FORKS+=("$repo|$remote")
    SKIPPED+=("$repo|a fork we own: $mine of the last $total subjects are ours, so the hooks would refuse what it receives")
    continue
  fi

  OURS+=("$repo|$remote")
done < <(find "$ROOT" -maxdepth 4 -name .git -type d \
           -not -path '*/node_modules/*' -not -path '*/_quarentena/*' \
           2>/dev/null | sort)

# ============================================================== check mode ===

if [ "$MODE" = check ]; then
  echo "fleet check: root $ROOT · $((${#OURS[@]})) repositories of ours"
  echo
  findings=0
  declare -a ALL_FINDINGS=()
  for row in "${OURS[@]}"; do
    repo="${row%%|*}"; remote="${row#*|}"
    name="${repo#"$ROOT"/}"
    declare -a bad=() notes=()

    [ "$(git -C "$repo" config core.hooksPath 2>/dev/null || true)" = "tools/git-hooks" ] \
      || bad+=("hooks not enabled (core.hooksPath)")

    for h in commit-msg pre-push; do
      if [ ! -f "$repo/tools/git-hooks/$h" ]; then
        bad+=("$h missing")
      elif generated_here "$repo/tools/git-hooks/$h" 'repodocs:hook'; then
        # Compare ignoring the one line each repository is allowed to rename.
        if ! diff -q <(grep -v '^HOOK_ESCAPE_VAR=' "$repo/tools/git-hooks/$h") \
                     <(grep -v '^HOOK_ESCAPE_VAR=' "$HOOK_SRC/$h") >/dev/null 2>&1; then
          bad+=("$h differs from the standard")
        fi
      fi
    done

    if [ -f "$repo/tools/release.sh" ] && generated_here "$repo/tools/release.sh" 'repodocs:tool'; then
      diff -q "$repo/tools/release.sh" "$TOOL_SRC/release.sh" >/dev/null 2>&1 \
        || bad+=("release.sh differs from the standard")
    elif [ ! -f "$repo/tools/release.sh" ] && [ ! -f "$repo/.github/workflows/release.yml" ]; then
      bad+=("no way to publish a Release (no release.sh, no workflow)")
    fi

    for b in $ECHO_BLOCKS; do
      grep -q "<!-- $b:repodocs -->" "$repo/CLAUDE.md" 2>/dev/null || bad+=("$b not stamped")
    done

    if [ -f "$repo/CLAUDE.md" ] && [ -f "$repo/AGENTS.md" ]; then
      diff -q <(tail -n +2 "$repo/CLAUDE.md") <(tail -n +2 "$repo/AGENTS.md") >/dev/null 2>&1 \
        || bad+=("CLAUDE.md and AGENTS.md differ below the H1 (ADR-007)")
    else
      bad+=("missing CLAUDE.md or AGENTS.md")
    fi

    # The rule is about the DEFAULT branch, not whatever is checked out: a
    # topic branch in the working tree is normal work, and flagging it would
    # teach whoever reads this report to skim past it.
    defbr="$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
    [ -n "$defbr" ] || defbr="$(git -C "$repo" config --get remote.origin.HEAD 2>/dev/null || true)"
    if [ -z "$defbr" ]; then
      # This clone was never told which branch is the remote's default. That is
      # a fact about the clone, not about the repository, so it is a note and
      # not a finding — counting it would inflate a number meant to be acted on.
      notes+=("default branch not known locally — git remote set-head origin -a")
    elif [ "$defbr" != master ]; then
      bad+=("default branch is '$defbr', not master (ADR-015)")
    fi

    if [ -f "$repo/version.md" ] && ! version_bump_is_safe "$repo"; then
      bad+=("version.md declares no current version — its first semver is a changelog heading, so a bump renumbers an entry instead of adding one")
    fi

    ign="$(ignored_standard_files "$repo" CHANGELOG.md version.md CLAUDE.md AGENTS.md tools/git-hooks tools/release.sh .continue)"
    [ -z "$ign" ] || bad+=("ignores files the standard tracks:$ign (golden rule 8 — an exception needs an ADR)")

    if [ -d "$repo/.continue" ]; then
      [ -f "$repo/.continue/README.md" ] || bad+=(".continue/ has no README.md (conventions §2)")
      untracked="$(git -C "$repo" ls-files --others --exclude-standard -- .continue 2>/dev/null | wc -l)"
      [ "${untracked:-0}" -eq 0 ] || bad+=("$untracked queue file(s) not in git — a deletion would not come back")
    fi

    if [ "$RELEASES" = 1 ] && [ -f "$repo/version.md" ]; then
      v="$(first_semver "$repo/version.md")"
      rel="$(gh release list --repo "$(slug_of "$remote")" --limit 1 2>/dev/null | awk '{print $1}')"
      [ -n "$v" ] && [ "$v" != "${rel:-}" ] && bad+=("version.md is $v, latest Release is ${rel:-none}")
    fi

    if [ "${#bad[@]}" -eq 0 ]; then
      printf '  ok    %s\n' "$name"
    else
      findings=$((findings + ${#bad[@]}))
      ALL_FINDINGS+=("${bad[@]}")
      printf '  ---   %s\n' "$name"
      printf '        · %s\n' "${bad[@]}"
    fi
    [ "${#notes[@]}" -eq 0 ] || printf '        note: %s\n' "${notes[@]}"
    unset bad notes
  done
  if [ "${#FORKS[@]}" -gt 0 ]; then
    echo
    echo "FORKS WE OWN (${#FORKS[@]}) — our version, and which upstream point it sits on:"
    for row in "${FORKS[@]}"; do
      repo="${row%%|*}"; remote="${row#*|}"
      name="${repo#"$ROOT"/}"
      declare -a fbad=()
      up="$(git -C "$repo" config --get remote.upstream.url 2>/dev/null || true)"

      if [ ! -f "$repo/version.md" ]; then
        fbad+=("no version.md — no version of our own at all")
      else
        v="$(first_semver "$repo/version.md")"
        if [ -z "$v" ]; then
          fbad+=("version.md carries no semver")
        elif grep -qE "$(printf '%s' "$v" | sed 's/\./\\./g')\+" "$repo/version.md"; then
          # "1.6.2+shvia.15": the first semver is the UPSTREAM's number, so every
          # tool in this fleet reads a version we do not control and cannot bump.
          fbad+=("the first semver is the upstream's ($v, in a local-version string) — our tools read a number we do not bump")
        fi
        grep -qiE '^[^#]*upstream' "$repo/version.md" 2>/dev/null \
          || fbad+=("version.md does not say which upstream point this fork sits on")
      fi
      [ -n "$up" ] || fbad+=("no 'upstream' remote configured — nothing records where it came from")

      if [ "${#fbad[@]}" -eq 0 ]; then
        printf '  ok    %s\n' "$name"
      else
        findings=$((findings + ${#fbad[@]}))
        ALL_FINDINGS+=("${fbad[@]}")
        printf '  ---   %s\n' "$name"
        printf '        · %s\n' "${fbad[@]}"
      fi
      unset fbad
    done
  fi

  echo
  if [ "$findings" -gt 0 ]; then
    echo "BY KIND — what to fix once instead of ${#OURS[@]} times:"
    printf '%s\n' "${ALL_FINDINGS[@]}" \
      | sed -E "s/'[^']*'/'…'/g; s/[0-9]+ queue file/N queue file/; s/version\.md is .*/version.md does not match its latest Release/" \
      | sort | uniq -c | sort -rn | sed 's/^/  /'
    echo
  fi
  echo "$findings finding(s) across ${#OURS[@]} repositories of ours and ${#FORKS[@]} forks we own."
  [ "$findings" -eq 0 ] || exit 1
  exit 0
fi

# ================================================ hooks and echo: selection ===

declare -a READY=()

for row in "${OURS[@]}"; do
  repo="${row%%|*}"; remote="${row#*|}"

  if reason="$(excluded_reason "$remote")"; then
    SKIPPED+=("$repo|$reason"); continue
  fi

  if [ ! -f "$repo/version.md" ] || [ -z "$(first_semver "$repo/version.md")" ]; then
    SKIPPED+=("$repo|no version.md with a semver — nothing to bump"); continue
  fi

  if ! version_bump_is_safe "$repo"; then
    SKIPPED+=("$repo|the first semver in version.md is a changelog heading — bumping it would renumber an entry that already happened, not add one")
    continue
  fi

  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  [ -n "$branch" ] || { SKIPPED+=("$repo|detached HEAD"); continue; }

  case "$MODE" in
    hooks)
      # A hook a repository wrote for itself is never overwritten. EOP's is the
      # case this protects: it runs the same version check through its own lint.
      if ! generated_here "$repo/tools/git-hooks/commit-msg" 'repodocs:hook'; then
        SKIPPED+=("$repo|has its own commit-msg — never overwritten"); continue
      fi
      touched="version.md CHANGELOG.md tools/git-hooks/commit-msg tools/git-hooks/pre-push tools/release.sh"
      ;;
    echo)
      if [ ! -f "$repo/CLAUDE.md" ] || [ ! -f "$repo/AGENTS.md" ]; then
        SKIPPED+=("$repo|no CLAUDE.md/AGENTS.md pair to stamp"); continue
      fi
      touched="version.md CHANGELOG.md CLAUDE.md AGENTS.md"
      ;;
  esac

  ign="$(blocking_ignored_files "$repo" $touched)"
  if [ -n "$ign" ]; then
    SKIPPED+=("$repo|ignores files the standard tracks and does not track them:$ign — git add would refuse, and -f is not the answer")
    continue
  fi

  dirty=""
  for f in $touched; do
    [ -e "$repo/$f" ] || continue     # a file that does not exist cannot be mid-edit
    if ! git -C "$repo" diff --quiet -- "$f" 2>/dev/null || ! git -C "$repo" diff --cached --quiet -- "$f" 2>/dev/null; then
      dirty="$dirty $f"
    fi
  done
  [ -z "$dirty" ] || { SKIPPED+=("$repo|in-flight edits to:$dirty"); continue; }

  READY+=("$repo|$remote")
done

# ------------------------------------------------------------------ report ---

echo "fleet $MODE: root $ROOT"
echo

if [ "$APPLY" -eq 0 ]; then
  echo "SELECTED (${#READY[@]}):"
  for row in "${READY[@]}"; do
    repo="${row%%|*}"; remote="${row#*|}"
    lang="EN"; pt_repository "$remote" && lang="PT"
    printf '  %-4s %s\n' "$lang" "${repo#"$ROOT"/}"
  done
  echo
  echo "SKIPPED (${#SKIPPED[@]}):"
  for row in "${SKIPPED[@]}"; do
    printf '  %-46s %s\n' "${row%%|*}" "${row#*|}" | sed "s#$ROOT/##"
  done
  echo
  echo "Dry run. Nothing was written. Re-run with --apply."
  exit 0
fi

echo "Applying to ${#READY[@]} repositories. A failure in one is a finding about"
echo "that one; the pass continues and reports everything at the end."
echo


# The changelog entry and the commit subject are the same sentence, written
# before the commit (conventions §1). SUBJECT is set as a side effect because
# the heading IS the subject and inventing it twice is how the two drift.
SUBJECT=""
write_entry() {     # $1 = file, $2 = remote, $3 = new version, $4 = escape var
  local f="$1" remote="$2" new="$3" ev="${4:-REPODOCS_NO_HOOK}"
  if [ "$MODE" = hooks ]; then
    if pt_repository "$remote"; then
      SUBJECT="$new - os hooks de git são regenerados a partir do repodocs"
      cat > "$f" <<PTENTRY
## $SUBJECT

Os dois hooks do padrão são reescritos a partir do repodocs, e o
\`tools/release.sh\` junto quando ele veio de lá. \`commit-msg\` confere a forma do
assunto (\`X.Y.Z - descrição\`), recusa prefixo de Conventional Commits e
mensagem vaga, **e confere que o \`X.Y.Z\` do assunto é a versão que este commit
carrega no \`version.md\`**. \`pre-push\` compara o \`version.md\` local com o do
branch padrão no remoto — versão repetida e versão que anda para trás — **só
quando o push realmente atualiza aquele branch**, de modo que deleção de branch,
tag e branch de tópico passam. Ele também avisa quando há arquivo em
\`.continue/\` fora do git: a recuperação de um item da fila depende de ele estar
versionado.

O hook **não confere idioma** e não teria como: o que ele mede é a forma e o
número.

Válvula de escape declarada nos dois: \`$ev=1\`. Num clone novo, ligue com
\`git config core.hooksPath tools/git-hooks\`.
PTENTRY
    else
      SUBJECT="$new - the git hooks are regenerated from repodocs"
      cat > "$f" <<ENENTRY
## $SUBJECT

Both hooks of the standard are rewritten from repodocs, and \`tools/release.sh\`
with them when it came from there. \`commit-msg\` checks the shape of the subject
(\`X.Y.Z - description\`), refuses a Conventional Commits prefix and a vague
message, **and checks that the subject's \`X.Y.Z\` is the version this commit
carries in \`version.md\`**. \`pre-push\` compares the local \`version.md\` against
the remote default branch for a repeated or a backwards version — **only when
the push actually updates that branch**, so a branch deletion, a tag and a topic
branch pass through. It also warns when \`.continue/\` holds files git does not
track: recovering a queue item depends on it being versioned.

The hook does **not** check the language and could not: what it measures is the
shape and the number.

Escape hatch, declared in both: \`$ev=1\`. In a fresh clone, enable them with
\`git config core.hooksPath tools/git-hooks\`.
ENENTRY
    fi
  else
    if pt_repository "$remote"; then
      SUBJECT="$new - os blocos de eco são regenerados a partir do repodocs"
      cat > "$f" <<PTENTRY
## $SUBJECT

As quatro regras marcadas de \`CLAUDE.md\` e \`AGENTS.md\` são reescritas a partir
da fonte única em [samirhvbr/repodocs](https://github.com/samirhvbr/repodocs):
\`QUEUE-RULE\`, \`RELEASES-RULE\`, \`LANGUAGE-RULE\` e \`COMMIT-RULE\`. Bloco é
substituído por inteiro entre os marcadores, cabeçalho incluído — é isso que faz
uma edição local não sobreviver e não confundir a próxima leitura.

O \`QUEUE-RULE\` é novo e chega pela primeira vez: a \`.continue/\` guarda trabalho
que ainda não existe, e um documento só sai dela quando a coisa que ele descreve
**existe**. Tamanho, idioma e desalinho não são condição de saída. **Nunca
esvazie essa pasta como arrumação.**
PTENTRY
    else
      SUBJECT="$new - the echo blocks are regenerated from repodocs"
      cat > "$f" <<ENENTRY
## $SUBJECT

The four marked rules in \`CLAUDE.md\` and \`AGENTS.md\` are rewritten from the
single source at [samirhvbr/repodocs](https://github.com/samirhvbr/repodocs):
\`QUEUE-RULE\`, \`RELEASES-RULE\`, \`LANGUAGE-RULE\` and \`COMMIT-RULE\`. A block is
replaced whole between its markers, heading included — which is what stops a
local edit from surviving a regeneration and confusing the next reader.

\`QUEUE-RULE\` is new and arrives here for the first time: \`.continue/\` holds work
that does not exist yet, and a document leaves it when — and only when — the
thing it describes **exists**. Length, language and untidiness are not exit
conditions. **Never empty that folder as tidying.**
ENENTRY
    fi
  fi
}

# ------------------------------------------------------------------- apply ---

TRAILERS="Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014qeYCqGQKLAdRPHEBpWbJC"

declare -a FAILED=() APPLIED=() CREATED_CHANGELOG=() CHANGELOG_IN_VERSION=()
ERR=""

# Undoes only what this pass wrote. `git reset -- .` would have unstaged
# whatever the person working in that repository had already staged, which is
# somebody else's work and none of this script's business.
rollback_one() {    # $1 = repo, $2 = mode, $3 = had_hooks, $4 = had_config, $5... = the paths we touched
  local repo="$1" mode="$2" had_hooks="$3" had_config="$4"; shift 4
  [ $# -eq 0 ] || git -C "$repo" reset -q -- "$@" 2>/dev/null || true
  git -C "$repo" checkout -- version.md 2>/dev/null || true
  [ -f "$repo/CHANGELOG.md" ] && git -C "$repo" checkout -- CHANGELOG.md 2>/dev/null
  if [ "$mode" = hooks ] && [ "$had_hooks" -eq 0 ]; then
    rm -f "$repo/tools/git-hooks/commit-msg" "$repo/tools/git-hooks/pre-push"
    rmdir "$repo/tools/git-hooks" 2>/dev/null || true
    rmdir "$repo/tools" 2>/dev/null || true
  fi
  [ "$mode" = echo ] && git -C "$repo" checkout -- CLAUDE.md AGENTS.md 2>/dev/null
  [ -z "$had_config" ] && git -C "$repo" config --unset core.hooksPath 2>/dev/null
  return 0
}

# One repository's failure is a finding about that repository, never the end of
# the batch. This runs with `set -e` suspended by its caller and checks its own
# commands: a refused `git add` in one clone used to end a pass over fifty, and
# the pass that died left two repositories with a written tree and no commit.
#
# Returns 0 applied · 2 nothing to do · 1 failed, with ERR saying why.
apply_one() {
  local repo="$1" remote="$2" name="$3"
  local had_hooks=1 had_config ev src b old new entry subject body out
  local -a paths=()
  ERR=""

  had_config="$(git -C "$repo" config core.hooksPath 2>/dev/null || true)"

  if [ "$MODE" = hooks ]; then
    [ -d "$repo/tools/git-hooks" ] || had_hooks=0
    mkdir -p "$repo/tools/git-hooks" || { ERR="cannot create tools/git-hooks"; return 1; }
    ev="$(escape_var_of "$repo/tools/git-hooks/commit-msg")"
    write_hook "$HOOK_SRC/commit-msg" "$repo/tools/git-hooks/commit-msg" "$ev" \
      || { ERR="cannot write commit-msg"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
    write_hook "$HOOK_SRC/pre-push" "$repo/tools/git-hooks/pre-push" "$ev" \
      || { ERR="cannot write pre-push"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
    paths=(tools/git-hooks/commit-msg tools/git-hooks/pre-push)

    if generated_here "$repo/tools/release.sh" 'repodocs:tool'; then
      cp "$TOOL_SRC/release.sh" "$repo/tools/release.sh" \
        && chmod +x "$repo/tools/release.sh" \
        && paths+=(tools/release.sh) \
        || { ERR="cannot write release.sh"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
    fi
    git -C "$repo" config core.hooksPath tools/git-hooks \
      || { ERR="cannot set core.hooksPath"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
  else
    for b in $ECHO_BLOCKS; do
      src="$(block_source "$b" "$remote")"
      stamp_block "$repo/CLAUDE.md" "$b" "$src" || { ERR="cannot stamp $b into CLAUDE.md"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
      stamp_block "$repo/AGENTS.md" "$b" "$src" || { ERR="cannot stamp $b into AGENTS.md"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
    done
    if ! diff -q <(tail -n +2 "$repo/CLAUDE.md") <(tail -n +2 "$repo/AGENTS.md") >/dev/null 2>&1; then
      ERR="the twins came out different after stamping (ADR-007)"
      rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" CLAUDE.md AGENTS.md
      return 1
    fi
    paths=(CLAUDE.md AGENTS.md)
  fi

  # --porcelain and not `diff`, because on a first install the files are
  # untracked and `git diff` is blind to them.
  [ -n "$(git -C "$repo" status --porcelain -- "${paths[@]}" 2>/dev/null)" ] || return 2

  old="$(first_semver "$repo/version.md")"
  new="$(bump_z "$old")"
  perl -0pi -e "s/\Q$old\E/$new/" "$repo/version.md" 2>/dev/null \
    || sed -i "0,/$old/s//$new/" "$repo/version.md" \
    || { ERR="cannot bump version.md"; rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"; return 1; }
  paths+=(version.md)

  entry="$(mktemp)"
  write_entry "$entry" "$remote" "$new" "${ev:-}"
  subject="$SUBJECT"

  # A changelog is recognised by what it IS — version headings — and not by the
  # word "changelog" in a title. KIDS/KIDS-PAVIO keeps its record in a
  # `version.md` titled "# Versões", so the word test missed it and this pass
  # created a second changelog beside the real one on 08/09/2026.
  if [ ! -f "$repo/CHANGELOG.md" ] && grep -qE '^#+ +([0-9]+\.[0-9]+\.[0-9]+|.*[Cc]hangelog|.*[Vv]ers)' "$repo/version.md" 2>/dev/null; then
    # The changelog lives inside version.md, in that repository's own heading
    # style. A second file beside it would be two changelogs that drift, in the
    # one file that decides what a version means.
    CHANGELOG_IN_VERSION+=("$name")
  else
    if [ ! -f "$repo/CHANGELOG.md" ]; then
      write_changelog_header "$repo/CHANGELOG.md" "$remote"
      CREATED_CHANGELOG+=("$name")
    fi
    prepend_changelog "$repo/CHANGELOG.md" "$entry"
    paths+=(CHANGELOG.md)
  fi
  rm -f "$entry"

  body="Regenerated from the single source at samirhvbr/repodocs. Editing one of these files in place does not survive the next pass; change it there."

  if ! out="$(git -C "$repo" add -- "${paths[@]}" 2>&1)"; then
    ERR="git add refused: $(printf '%s' "$out" | head -n 2 | tr '\n' ' ')"
    rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"
    return 1
  fi

  # The commit goes THROUGH the hooks it installs. A repository that would
  # refuse its own regeneration says so instead of being forced.
  if ! out="$(git -C "$repo" commit -q -m "$subject" -m "$body" -m "$TRAILERS" -- "${paths[@]}" 2>&1)"; then
    ERR="commit refused: $(printf '%s' "$out" | grep -m1 -E 'REJECTED|error|fatal' || printf '%s' "$out" | head -n 1)"
    rollback_one "$repo" "$MODE" "$had_hooks" "$had_config" "${paths[@]}"
    return 1
  fi
  echo "  +    $name — $subject"

  if [ "$PUSH" -eq 0 ]; then
    APPLIED+=("$name|$subject")
    return 0
  fi

  out="$(git -C "$repo" push 2>&1)" && { APPLIED+=("$name|$subject"); return 0; }

  # The one refusal worth retrying is a remote that moved while we worked. The
  # retry is a fetch and a replay of our own commit on top of it — never a
  # force, never a merge nobody verified. A dirty tree or a conflicting replay
  # is a decision about someone else's work, and that decision is not this
  # script's (ADR-018).
  if printf '%s' "$out" | grep -qE 'fetch first|non-fast-forward|behind'; then
    if [ -n "$(git -C "$repo" status --porcelain 2>/dev/null)" ]; then
      ERR="push refused (the remote moved) and the tree is not clean — the commit stays local"
    elif git -C "$repo" fetch -q origin 2>/dev/null && git -C "$repo" rebase -q '@{upstream}' >/dev/null 2>&1; then
      if out="$(git -C "$repo" push 2>&1)"; then
        echo "  ~    $name — the remote had moved; replayed on top of it and pushed"
        APPLIED+=("$name|$subject")
        return 0
      fi
      ERR="rebased cleanly and the push was still refused: $(printf '%s' "$out" | grep -m1 -E 'REJECTED|rejected|error' || printf '%s' "$out" | tail -n 1)"
    else
      git -C "$repo" rebase --abort >/dev/null 2>&1 || true
      ERR="push refused and the replay was not trivial — the commit stays local, unchanged"
    fi
  else
    ERR="push refused: $(printf '%s' "$out" | grep -m1 -E 'REJECTED|rejected|error|fatal' || printf '%s' "$out" | tail -n 1)"
  fi
  return 1
}

for row in "${READY[@]}"; do
  repo="${row%%|*}"; remote="${row#*|}"
  name="${repo#"$ROOT"/}"

  set +e
  apply_one "$repo" "$remote" "$name"
  rc=$?
  set -e

  case "$rc" in
    0) ;;
    2) echo "  =    $name — already current" ;;
    *) echo "  !    $name — ${ERR:-unknown failure}"
       FAILED+=("$name|${ERR:-unknown failure}") ;;
  esac
done

echo
echo "=============================================================================="
echo "APPLIED (${#APPLIED[@]}):"
if [ "${#APPLIED[@]}" -eq 0 ]; then
  echo "  (none)"
else
  for row in "${APPLIED[@]}"; do printf '  %-34s %s\n' "${row%%|*}" "${row#*|}"; done
fi

echo
echo "SKIPPED (${#SKIPPED[@]}):"
for row in "${SKIPPED[@]}"; do
  printf '  %-46s %s\n' "${row%%|*}" "${row#*|}" | sed "s#$ROOT/##"
done

echo
echo "FAILED (${#FAILED[@]}):"
if [ "${#FAILED[@]}" -eq 0 ]; then
  echo "  (none)"
else
  for row in "${FAILED[@]}"; do printf '  %-34s %s\n' "${row%%|*}" "${row#*|}"; done
fi
echo "=============================================================================="

if [ "${#CREATED_CHANGELOG[@]}" -gt 0 ]; then
  echo
  echo "CHANGELOG.md CREATED — the repository had none (${#CREATED_CHANGELOG[@]}):"
  printf '  %s\n' "${CREATED_CHANGELOG[@]}"
fi
if [ "${#CHANGELOG_IN_VERSION[@]}" -gt 0 ]; then
  echo
  echo "CHANGELOG LIVES INSIDE version.md — no entry written, no second file created (${#CHANGELOG_IN_VERSION[@]}):"
  printf '  %s\n' "${CHANGELOG_IN_VERSION[@]}"
fi

echo
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "${#APPLIED[@]} applied · ${#SKIPPED[@]} skipped · ${#FAILED[@]} failed. Every repository was attempted."
  exit 1
fi
if [ "$PUSH" -eq 1 ]; then
  echo "${#APPLIED[@]} applied and pushed · ${#SKIPPED[@]} skipped · nothing failed."
else
  echo "${#APPLIED[@]} applied · ${#SKIPPED[@]} skipped · nothing failed; nothing was pushed (--no-push)."
fi
