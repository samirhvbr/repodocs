#!/usr/bin/env bash
# fleet-hooks.sh — put the two git hooks into the repositories of the fleet, and
# turn them on.
#
# Why this exists: on 07/09/2026 the hooks were enabled in 3 clones out of 58.
# Everywhere else the commit format was prose in a CLAUDE.md, which is what
# prose becomes at the end of a long session — advisory. Two repositories were
# measurably off the norm and neither had a mechanical guard that would have
# said so.
#
# What it refuses to do is as important as what it does. It never overwrites a
# hook a repository wrote for itself (EOP's is stronger than this one), never
# touches a repository whose history follows another convention (our forks of
# upstream projects), and never commits a file the working tree is already
# mid-edit on.
#
# Norm: docs/versioning.md · procedure: docs/runbook.md
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPODOCS="$(dirname "$SELF_DIR")"
SRC="$REPODOCS/templates/skeleton/tools/git-hooks"

ROOT="${HOME}/x"
APPLY=0
PUSH=1
FILTER=""

usage() {
  cat <<USAGE
usage: tools/fleet-hooks.sh [--apply] [--no-push] [--root DIR] [--only SUBSTRING]

  (default)          dry run: classify every repository, change nothing
  --apply            write the hooks, enable them, bump, commit and push
  --no-push          commit but do not push (a refused push is a human's call)
  --root DIR         where the fleet lives (default: \$HOME/x)
  --only SUBSTRING   restrict to repositories whose path contains SUBSTRING

Each selected repository gets one commit: the two hooks, the version bump and
the changelog entry, in the language that repository is written in.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --no-push) PUSH=0 ;;
    --root) ROOT="$2"; shift ;;
    --only) FILTER="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[ -f "$SRC/commit-msg" ] && [ -f "$SRC/pre-push" ] || {
  echo "fleet-hooks: cannot find the hook sources at $SRC" >&2
  exit 1
}

# The owners whose repositories are ours. Anything else is a repository we are
# guests in, where the host's conventions win (ADR-019) — including our own
# forks of upstream projects, which keep the upstream's commit shape.
FLEET_OWNERS="samirhvbr BLUE3-ISP"

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

first_semver() {    # $1 = file
  grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$1" | head -n 1 || true
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

# ---------------------------------------------------------------- classify ---

declare -a READY=() SKIPPED=()

while IFS= read -r gitdir; do
  repo="$(dirname "$gitdir")"
  [ -n "$FILTER" ] && case "$repo" in *"$FILTER"*) ;; *) continue ;; esac
  [ "$(cd "$repo" && pwd)" = "$REPODOCS" ] && { SKIPPED+=("$repo|the source of the hooks — enabled here already"); continue; }

  remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  [ -n "$remote" ] || { SKIPPED+=("$repo|no origin remote"); continue; }

  if reason="$(excluded_reason "$remote")"; then
    SKIPPED+=("$repo|$reason"); continue
  fi

  owner="$(owner_of "$remote")"
  case " $FLEET_OWNERS " in
    *" $owner "*) ;;
    *) SKIPPED+=("$repo|not ours — owner is $owner, the host's conventions win"); continue ;;
  esac

  [ -f "$repo/version.md" ] || { SKIPPED+=("$repo|no version.md — the hooks have nothing to measure"); continue; }
  [ -n "$(first_semver "$repo/version.md")" ] || { SKIPPED+=("$repo|version.md holds no semver"); continue; }

  # Does this repository write our subjects *now*? A fork we own but that tracks
  # an upstream does not, and installing the hook there would refuse every
  # commit it is about to receive.
  #
  # The window is the last 5 non-merge subjects, and it is short on purpose. A
  # twenty-commit window reaches back past 03/09/2026, when the format became
  # universal, and reads a repository's own pre-rule history as evidence that it
  # follows another convention — measured: six fleet repositories scored 8/20
  # and would have been skipped. At five, the fleet scores 4/5 or 5/5 and the
  # upstream forks score 0/5. The separation is not marginal.
  total="$(git -C "$repo" log --no-merges --format='%s' -5 2>/dev/null | grep -c . || true)"
  [ "${total:-0}" -gt 0 ] || { SKIPPED+=("$repo|no history to read"); continue; }
  ours="$(git -C "$repo" log --no-merges --format='%s' -5 2>/dev/null | grep -cE '^[0-9]+\.[0-9]+\.[0-9]+ - ' || true)"
  if [ "$((ours * 2))" -lt "$total" ]; then
    SKIPPED+=("$repo|history follows another convention ($ours of the last $total subjects are ours)")
    continue
  fi

  # A hook a repository wrote for itself is never overwritten. EOP's is the case
  # this protects: it runs the same version check through its own lint, has a
  # toolchain behind it and is stronger than this one.
  #
  # A hook that came from here before the provenance marker existed is *not*
  # that case, and it must still be regenerated — it is recognised by the two
  # things only a generated copy has: the `HOOK_ESCAPE_VAR` line and the
  # rejection text that names this norm.
  hook="$repo/tools/git-hooks/commit-msg"
  if [ -f "$hook" ] \
     && ! grep -q 'repodocs:hook' "$hook" \
     && ! { grep -q '^HOOK_ESCAPE_VAR=' "$hook" && grep -q 'commit-msg: REJECTED' "$hook"; }; then
    SKIPPED+=("$repo|has its own commit-msg — never overwritten")
    continue
  fi

  dirty=""
  for f in version.md CHANGELOG.md tools/git-hooks/commit-msg tools/git-hooks/pre-push; do
    if ! git -C "$repo" diff --quiet -- "$f" 2>/dev/null || ! git -C "$repo" diff --cached --quiet -- "$f" 2>/dev/null; then
      dirty="$dirty $f"
    fi
  done
  [ -z "$dirty" ] || { SKIPPED+=("$repo|in-flight edits to:$dirty"); continue; }

  branch="$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  [ -n "$branch" ] || { SKIPPED+=("$repo|detached HEAD"); continue; }

  READY+=("$repo|$remote")
done < <(find "$ROOT" -maxdepth 4 -name .git -type d \
           -not -path '*/node_modules/*' -not -path '*/_quarentena/*' \
           2>/dev/null | sort)

# ------------------------------------------------------------------ report ---

echo "fleet-hooks: root $ROOT"
echo
echo "SELECTED (${#READY[@]}):"
for row in "${READY[@]}"; do
  repo="${row%%|*}"; remote="${row#*|}"
  lang="EN"; pt_repository "$remote" && lang="PT"
  action="install"
  [ -f "$repo/tools/git-hooks/commit-msg" ] && action="regenerate"
  printf '  %-8s %-12s %s\n' "$action" "$lang" "${repo#"$ROOT"/}"
done
echo
echo "SKIPPED (${#SKIPPED[@]}):"
for row in "${SKIPPED[@]}"; do
  printf '  %-46s %s\n' "${row%%|*}" "${row#*|}" | sed "s#$ROOT/##"
done
echo

if [ "$APPLY" -eq 0 ]; then
  echo "Dry run. Nothing was written. Re-run with --apply to install."
  exit 0
fi

# ------------------------------------------------------------------- apply ---

TRAILERS="Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_014qeYCqGQKLAdRPHEBpWbJC"

declare -a FAILED=() NO_CHANGELOG=()

for row in "${READY[@]}"; do
  repo="${row%%|*}"; remote="${row#*|}"
  name="${repo#"$ROOT"/}"
  action="install"
  [ -f "$repo/tools/git-hooks/commit-msg" ] && action="regenerate"

  had_hooks=1
  [ -d "$repo/tools/git-hooks" ] || had_hooks=0
  had_config="$(git -C "$repo" config core.hooksPath || true)"

  mkdir -p "$repo/tools/git-hooks"
  ev="$(escape_var_of "$repo/tools/git-hooks/commit-msg")"
  write_hook "$SRC/commit-msg" "$repo/tools/git-hooks/commit-msg" "$ev"
  write_hook "$SRC/pre-push"   "$repo/tools/git-hooks/pre-push"   "$ev"
  git -C "$repo" config core.hooksPath tools/git-hooks

  # --porcelain and not `diff`, because on a first install the hooks are
  # untracked and `git diff` is blind to them.
  if [ -z "$(git -C "$repo" status --porcelain -- tools/git-hooks)" ]; then
    echo "  = $name — hooks already current, only the config was set"
    continue
  fi

  old="$(first_semver "$repo/version.md")"
  new="$(bump_z "$old")"
  # The first semver in the file is the version, whatever shape the file has.
  perl -0pi -e "s/\Q$old\E/$new/" "$repo/version.md" 2>/dev/null || \
    sed -i "0,/$old/s//$new/" "$repo/version.md"

  entry="$(mktemp)"
  if pt_repository "$remote"; then
    subject="$new - os hooks de git passam a rodar neste repositório"
    [ "$action" = regenerate ] && subject="$new - os hooks de git são regenerados a partir do repodocs"
    cat > "$entry" <<PTENTRY
## $subject

Os dois hooks do padrão passam a rodar aqui: \`commit-msg\`, que confere a forma
do assunto (\`X.Y.Z - descrição\`), recusa prefixo de Conventional Commits e
mensagem vaga, **e confere que o \`X.Y.Z\` do assunto é a versão que este commit
carrega no \`version.md\`**; e \`pre-push\`, que compara o \`version.md\` local com o
do branch padrão no remoto — versão repetida e versão que anda para trás.

O hook **não confere idioma** e não teria como: o que ele mede é a forma e o
número. Este repositório é escrito em português por decisão registrada
(ADR-020 do repodocs), e nada nos hooks muda por causa disso.

Até agora a regra do commit vivia só como prosa no \`CLAUDE.md\`, e prosa é o que
se esquece no fim de uma sessão longa. Em 07/09/2026 os hooks estavam ligados em
3 clones de 58, e dois repositórios da frota estavam medidamente fora da norma
sem que nada avisasse.

Válvula de escape declarada nos dois: \`$ev=1\`. Ela existe para o hook continuar
instalado — guarda sem escape declarado vira \`--no-verify\`, que desliga todas de
uma vez. Num clone novo, ligue com \`git config core.hooksPath tools/git-hooks\`.
PTENTRY
  else
    subject="$new - the git hooks arrive from repodocs and are enabled here"
    [ "$action" = regenerate ] && subject="$new - the git hooks are regenerated from repodocs"
    cat > "$entry" <<ENENTRY
## $subject

Both hooks of the standard now run here: \`commit-msg\`, which checks the shape of
the subject (\`X.Y.Z - description\`), refuses a Conventional Commits prefix and a
vague message, **and checks that the subject's \`X.Y.Z\` is the version this commit
carries in \`version.md\`**; and \`pre-push\`, which compares the local \`version.md\`
against the remote default branch for a repeated version and for one that moves
backwards.

The hook does **not** check the language and could not: what it measures is the
shape and the number.

Until now the commit rule lived here only as prose in \`CLAUDE.md\`, and prose is
what gets forgotten at the end of a long session. On 07/09/2026 the hooks were
enabled in 3 clones out of 58, and two repositories of the fleet were measurably
off the norm with nothing to say so.

Escape hatch, declared in both: \`$ev=1\`. It exists so the hooks stay installed —
a guard with no declared bypass gets bypassed with \`--no-verify\`, which switches
off every guard at once. In a fresh clone, enable them with
\`git config core.hooksPath tools/git-hooks\`.
ENENTRY
  fi

  paths=(tools/git-hooks/commit-msg tools/git-hooks/pre-push version.md)
  if [ -f "$repo/CHANGELOG.md" ]; then
    prepend_changelog "$repo/CHANGELOG.md" "$entry"
    paths+=(CHANGELOG.md)
  else
    # Some repositories keep their changelog inside version.md instead. The
    # entry is not invented into a file that does not exist; the subject and
    # the bump still land, and the report says which repositories these are.
    NO_CHANGELOG+=("$name")
  fi
  rm -f "$entry"

  body="$(printf '%s\n\n%s\n' \
    "The hooks were enabled in 3 clones out of 58 on 07/09/2026, so the commit rule was prose everywhere else. commit-msg now also checks that the subject's version is the one version.md carries in this commit; pre-push still asks the remote about duplicates and about a version moving backwards. Neither checks the language." \
    "Escape hatch declared in both: $ev=1. Enable in a fresh clone with git config core.hooksPath tools/git-hooks.")"

  # A pathspec commit only reaches tracked files, and on a first install the
  # hooks are not tracked yet — so they are staged first. Nothing else the
  # repository has staged is touched: the pathspec is what gets committed.
  git -C "$repo" add -- "${paths[@]}"

  # The commit that installs the hook goes THROUGH the hook it installs. If the
  # subject or the bump is wrong, the repository refuses its own installation,
  # which is the strongest test this script can run and costs nothing.
  if ! git -C "$repo" commit -q \
        -m "$subject" -m "$body" \
        -m "$TRAILERS" \
        -- "${paths[@]}"; then
    FAILED+=("$name|commit refused — the repository was left as it was found")
    echo "  ! $name — commit refused, rolling back"
    git -C "$repo" reset -q -- "${paths[@]}" 2>/dev/null || true
    git -C "$repo" checkout -- version.md 2>/dev/null || true
    [ -f "$repo/CHANGELOG.md" ] && git -C "$repo" checkout -- CHANGELOG.md 2>/dev/null || true
    if [ "$had_hooks" -eq 0 ]; then
      rm -f "$repo/tools/git-hooks/commit-msg" "$repo/tools/git-hooks/pre-push"
      rmdir "$repo/tools/git-hooks" 2>/dev/null || true
      rmdir "$repo/tools" 2>/dev/null || true
    fi
    if [ -z "$had_config" ]; then
      git -C "$repo" config --unset core.hooksPath 2>/dev/null || true
    fi
    continue
  fi
  echo "  + $name — $subject"

  if [ "$PUSH" -eq 1 ]; then
    if ! out="$(git -C "$repo" push 2>&1)"; then
      FAILED+=("$name|push refused: $(printf '%s' "$out" | tail -n 1)")
      echo "  ! $name — PUSH REFUSED"
      printf '%s\n' "$out" | sed 's/^/      /'
    fi
  fi
done

echo
if [ "${#NO_CHANGELOG[@]}" -gt 0 ]; then
  echo "NO CHANGELOG.md — subject and bump landed, no entry written (${#NO_CHANGELOG[@]}):"
  printf '  %s\n' "${NO_CHANGELOG[@]}"
  echo
fi
if [ "${#FAILED[@]}" -gt 0 ]; then
  echo "NEEDS A PERSON (${#FAILED[@]}):"
  for row in "${FAILED[@]}"; do printf '  %-40s %s\n' "${row%%|*}" "${row#*|}"; done
  exit 1
fi
if [ "$PUSH" -eq 1 ]; then
  echo "Done. Every selected repository is committed and pushed."
else
  echo "Done. Every selected repository is committed; nothing was pushed (--no-push)."
fi
