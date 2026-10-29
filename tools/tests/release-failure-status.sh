#!/usr/bin/env bash
# Run: bash tools/tests/release-failure-status.sh
# API failures and partial backfills through the real helper. All remotes are
# local; gh is a stub, and neither GitHub nor a real release is touched.
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
  'release list')
    [ "$FIXTURE_MODE" != list_failure ] || exit 1
    cat "$FIXTURE_CAPTURE/published" ;;
  'api rate_limit')
    case "$FIXTURE_MODE" in
      quota_failure) exit 1 ;;
      quota_invalid) echo unknown ;;
      quota_low) echo 0 ;;
      quota_after_first) if [ -s "$FIXTURE_CAPTURE/created" ]; then echo 0; else echo 5000; fi ;;
      *) echo 5000 ;;
    esac ;;
  'release create')
    [ "$FIXTURE_MODE" != create_failure ] || { echo 'fixture create failed' >&2; exit 1; }
    printf '%s\n' "$3" >> "$FIXTURE_CAPTURE/created"
    printf '%s\n' "$3" >> "$FIXTURE_CAPTURE/published"
    if [ "$FIXTURE_MODE" = new_push ]; then
      printf '1.2.4\n' > "$FIXTURE_WRITER/version.md"
      git -C "$FIXTURE_WRITER" commit -qam '1.2.4 - new remote version'
      git -C "$FIXTURE_WRITER" push -q origin master
    fi ;;
  'release view')
    if [ "$3" != --repo ]; then
      grep -Fxq -- "$3" "$FIXTURE_CAPTURE/published"
      exit
    fi
    [ "$FIXTURE_MODE" != latest_view_failure ] || exit 1
    if [ "$FIXTURE_MODE" = final_fetch_failure ]; then
      git remote set-url origin "$FIXTURE_CAPTURE/no-such-remote.git"
    fi
    if [ -f "$FIXTURE_CAPTURE/edited" ] && [ "$FIXTURE_MODE" != latest_verify_failure ]; then
      cat "$FIXTURE_CAPTURE/edited"
    else
      case "$FIXTURE_MODE" in
        latest_edit_failure|latest_verify_failure|create_failure|legacy) echo 1.2.2 ;;
        *) printf '%s\n' "$FIXTURE_CURRENT" ;;
      esac
    fi ;;
  'release edit')
    [ "$FIXTURE_MODE" != latest_edit_failure ] || exit 1
    printf '%s\n' "$3" > "$FIXTURE_CAPTURE/edited" ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$TMP/bin/gh"

FAILED=0
ok() { printf '  ok  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1" >&2; FAILED=1; }
new_case() {
  CASE="$TMP/$1"
  git init -q --bare -b master "$CASE.git"
  git init -q -b master "$CASE-writer"
  git -C "$CASE-writer" remote add origin "$CASE.git"
  printf '1.2.3\n' > "$CASE-writer/version.md"
  printf '## 1.2.3 - fixture\n\nFixture notes.\n' > "$CASE-writer/CHANGELOG.md"
  git -C "$CASE-writer" add -A
  git -C "$CASE-writer" commit -qm '1.2.3 - fixture'
  git -C "$CASE-writer" push -q origin master
  git clone -q "$CASE.git" "$CASE"
  cd "$CASE"
  export FIXTURE_CAPTURE="$CASE-capture" FIXTURE_WRITER="$CASE-writer"
  export FIXTURE_CURRENT=1.2.3 FIXTURE_MODE="$2"
  mkdir "$FIXTURE_CAPTURE"
  : > "$FIXTURE_CAPTURE/published"
}
run_release() {
  bash "$RELEASE" --repo fixture/release --sleep 0 "$@" > "$FIXTURE_CAPTURE/output" 2>&1
}
must_fail() {
  local description="$1"; shift
  if run_release "$@"; then bad "$description"; else ok "$description"; fi
}
no_writes() {
  if grep -Eq '^release (create|edit) ' "$FIXTURE_CAPTURE/calls"; then bad "$1"; else ok "$1"; fi
}

for mode in current backfill; do
  for fault in list_failure quota_failure quota_invalid quota_low; do
    new_case "$mode-$fault" "$fault"
    must_fail "$mode reports $fault with a failing status" "--$mode"
    no_writes "$mode makes no release write after $fault"
  done
done

new_case partial quota_after_first
printf '1.2.4\n' > "$FIXTURE_WRITER/version.md"
git -C "$FIXTURE_WRITER" commit -qam '1.2.4 - second fixture version'
git -C "$FIXTURE_WRITER" push -q origin master
export FIXTURE_CURRENT=1.2.4
must_fail 'quota exhaustion after a partial backfill is not success' --backfill
[ "$(cat "$FIXTURE_CAPTURE/created")" = 1.2.3 ] \
  && ok 'the partial backfill stopped after its first release' || bad 'the partial backfill did not stop'
export FIXTURE_MODE=normal
run_release --backfill && ok 'a rerun resumes the partial backfill' || bad 'the resumed backfill failed'
[ "$(sort "$FIXTURE_CAPTURE/created" | uniq -d | wc -l | tr -d ' ')" = 0 ] \
  && ok 'the rerun creates no duplicate release' || bad 'the rerun duplicated a release'
[ "$(wc -l < "$FIXTURE_CAPTURE/created" | tr -d ' ')" = 2 ] \
  && ok 'the resumed backfill publishes the remaining version' || bad 'the resumed backfill missed a version'

for fault in latest_view_failure latest_edit_failure latest_verify_failure final_fetch_failure; do
  new_case "$fault" "$fault"
  must_fail "$fault is reported instead of a successful run"
done

new_case create-failure create_failure
must_fail 'a failed create is a failed run'
if grep -q '^release edit ' "$FIXTURE_CAPTURE/calls"; then
  bad 'a failed publication must not continue with badge mutations'
else
  ok 'a failed publication does not continue with badge mutations'
fi

new_case changed-remote new_push
must_fail 'a new remote version without a release is an explicit incomplete run'
[ "$(cat "$FIXTURE_CAPTURE/created")" = 1.2.3 ] \
  && ok 'the helper does not publish the newly arrived version implicitly' || bad 'a new version was published implicitly'

new_case legacy legacy
printf 'v1.2.3\n' > "$FIXTURE_CAPTURE/published"
run_release && ok 'an existing legacy release can be reconciled' || bad 'legacy reconciliation failed'
[ "$(cat "$FIXTURE_CAPTURE/edited" 2>/dev/null || true)" = v1.2.3 ] \
  && ok 'Latest is verified on the existing legacy tag' || bad 'the legacy badge was not corrected'
[ ! -e "$FIXTURE_CAPTURE/created" ] \
  && ok 'a legacy release is not duplicated' || bad 'the legacy release was duplicated'

new_case dry-run quota_low
run_release --dry-run && ok 'dry run does not require a write budget' || bad 'dry run required write quota'
no_writes 'dry run sends no release mutations'

exit "$FAILED"
