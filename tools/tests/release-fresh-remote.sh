#!/usr/bin/env bash
# Run: bash tools/tests/release-fresh-remote.sh
# The real release helper, local bare remotes and a gh stub: no GitHub writes.
set -euo pipefail

RELEASE="$(cd "$(dirname "$0")/.." && pwd)/release.sh"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/bin"
export PATH="$TMP/bin:$PATH"
cat > "$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FIXTURE_CAPTURE/calls"
case "$1 $2" in
  'api rate_limit') echo 5000 ;;
  'release list')
    if [ -n "${FIXTURE_MOVE_SHA:-}" ]; then
      git update-ref refs/remotes/origin/master "$FIXTURE_MOVE_SHA"
    fi
    if [ -n "${FIXTURE_ADVANCE_SHA:-}" ]; then
      git --git-dir="$FIXTURE_REMOTE" update-ref refs/heads/master "$FIXTURE_ADVANCE_SHA"
    fi ;;
  'release view')
    if [ -f "$FIXTURE_CAPTURE/latest" ]; then cat "$FIXTURE_CAPTURE/latest"
    else printf '%s\n' "$FIXTURE_LATEST"; fi ;;
  'release edit') printf '%s\n' "$3" > "$FIXTURE_CAPTURE/latest" ;;
  'release create')
    version="$3"; target=""; latest="unspecified"; shift 3
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --target) target="$2"; shift ;;
        --latest|--latest=*) latest="$1" ;;
        --repo|--title|--notes-file) shift ;;
        --generate-notes) : ;;
        *) echo "unexpected create argument: $1" >&2; exit 2 ;;
      esac
      shift
    done
    printf '%s %s %s\n' "$version" "$target" "$latest" >> "$FIXTURE_CAPTURE/created" ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$TMP/bin/gh"

FAILED=0
ok() { printf '  ok  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1" >&2; FAILED=1; }
new_case() {
  CASE="$TMP/$1"
  BRANCH="${2:-master}"
  git init -q --bare -b "$BRANCH" "$CASE.git"
  git init -q -b "$BRANCH" "$CASE-writer"
  git -C "$CASE-writer" remote add origin "$CASE.git"
  update_remote 1.2.3
  OLD_SHA="$REMOTE_SHA"
  git clone -q "$CASE.git" "$CASE"
  cd "$CASE"
  export FIXTURE_CAPTURE="$CASE-capture" FIXTURE_LATEST=1.2.3 FIXTURE_MOVE_SHA=""
  export FIXTURE_ADVANCE_SHA="" FIXTURE_REMOTE="$CASE.git"
  mkdir "$FIXTURE_CAPTURE"
}
update_remote() {
  printf '%s\n' "$1" > "$CASE-writer/version.md"
  printf '## %s - fixture\n\nNotes for %s.\n' "$1" "$1" > "$CASE-writer/CHANGELOG.md"
  git -C "$CASE-writer" add -A
  git -C "$CASE-writer" commit -qm "$1 - fixture"
  git -C "$CASE-writer" push -q origin "$BRANCH"
  REMOTE_SHA="$(git -C "$CASE-writer" rev-parse HEAD)"
}
run_release() {
  bash "$RELEASE" --repo fixture/release --sleep 0 "$@" > "$FIXTURE_CAPTURE/output" 2>&1 \
    || { cat "$FIXTURE_CAPTURE/output" >&2; exit 1; }
}
created() {
  grep -Fq -- "$1" "$FIXTURE_CAPTURE/created" && ok "$2" || bad "$2"
}

new_case current
update_remote 1.2.4
export FIXTURE_LATEST=1.2.4
run_release
created "1.2.4 $REMOTE_SHA --latest" 'current publishes the fresh remote version and commit'
[ "$(wc -l < "$FIXTURE_CAPTURE/created" | tr -d ' ')" = 1 ] \
  && ok 'current publishes one version' || bad 'current published more than one version'

new_case backfill
update_remote 1.2.4
export FIXTURE_LATEST=1.2.4
run_release --backfill
created "1.2.3 $OLD_SHA" 'backfill keeps the historical target'
created "1.2.4 $REMOTE_SHA --latest" 'backfill includes versions pushed since the last local fetch'

new_case missing-default dev
git symbolic-ref --delete refs/remotes/origin/HEAD
git switch -qc topic
printf '1.2.5\n' > version.md
git commit -qam '1.2.5 - unpublished local work'
run_release
created "1.2.3 $REMOTE_SHA --latest" 'a missing tracking HEAD resolves the remote default, even on a topic branch'

new_case moving-ref
update_remote 1.2.4
git fetch -q origin
export FIXTURE_LATEST=1.2.4 FIXTURE_MOVE_SHA="$OLD_SHA"
run_release
created "1.2.4 $REMOTE_SHA --latest" 'a concurrent tracking-ref change cannot move the selected target'

new_case historical
update_remote 1.2.4
export FIXTURE_LATEST=1.2.4
run_release --ref "$OLD_SHA"
created "1.2.3 $OLD_SHA --latest=false" 'an explicit historical ref never takes the remote current version Latest badge'

new_case restricted-fetch
git --git-dir="$CASE.git" update-ref refs/heads/topic "$OLD_SHA"
git config remote.origin.fetch '+refs/heads/topic:refs/remotes/origin/topic'
update_remote 1.2.4
export FIXTURE_LATEST=1.2.4
run_release
created "1.2.4 $REMOTE_SHA --latest" 'current refreshes the default even when the configured refspec excludes it'
: > "$FIXTURE_CAPTURE/created"
run_release --backfill
created "1.2.3 $OLD_SHA --latest=false" 'a restricted fetch preserves historical backfill targets'
created "1.2.4 $REMOTE_SHA --latest" 'backfill includes the current default despite a restricted fetch'

new_case restricted-reconcile
update_remote 1.2.4
git --git-dir="$CASE.git" update-ref refs/heads/topic "$REMOTE_SHA"
git --git-dir="$CASE.git" update-ref refs/heads/master "$OLD_SHA"
git config remote.origin.fetch '+refs/heads/topic:refs/remotes/origin/topic'
export FIXTURE_ADVANCE_SHA="$REMOTE_SHA"
run_release
created "1.2.3 $OLD_SHA --latest" 'a mid-run remote advance does not change the pinned release target'
grep -Fq 'release edit 1.2.4 --repo fixture/release --latest' "$FIXTURE_CAPTURE/calls" \
  && ok 'reconciliation refreshes the default despite a restricted fetch' \
  || bad 'reconciliation left Latest on the old default version'

new_case explicit-branch
git -C "$CASE-writer" switch -qc topic
BRANCH=topic
update_remote 1.3.0
run_release --ref origin/topic
created "1.3.0 $REMOTE_SHA --latest=false" 'an explicit non-default history is refreshed and cannot take Latest'

new_case unavailable
git remote set-url origin "$TMP/no-such-remote.git"
if bash "$RELEASE" --repo fixture/release --sleep 0 > "$FIXTURE_CAPTURE/output" 2>&1; then
  bad 'an unavailable remote must stop with a failing status'
else
  ok 'an unavailable remote stops with a failing status'
fi
[ ! -e "$FIXTURE_CAPTURE/calls" ] \
  && ok 'a failed refresh reaches no GitHub operation' || bad 'GitHub was contacted after a failed refresh'

exit "$FAILED"
