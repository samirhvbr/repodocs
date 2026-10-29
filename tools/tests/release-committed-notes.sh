#!/usr/bin/env bash
# Run: bash tools/tests/release-committed-notes.sh
# Exercise the real helper with local Git repositories and a gh stub. Nothing
# reaches GitHub: only the notes and target passed to release create are kept.
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
case "$1 $2" in
  'api rate_limit') echo 5000 ;;
  'release list') : ;;
  'release view') printf '%s\n' "$FIXTURE_CURRENT" ;;
  'release edit') : ;;
  'release create')
    shift 3
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --notes-file) cp "$2" "$FIXTURE_CAPTURE/notes"; shift ;;
        --generate-notes) touch "$FIXTURE_CAPTURE/generated" ;;
        --target) printf '%s\n' "$2" > "$FIXTURE_CAPTURE/target"; shift ;;
        --repo|--title) shift ;;
        --latest) : ;;
        *) echo "unexpected create argument: $1" >&2; exit 2 ;;
      esac
      shift
    done ;;
  *) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$TMP/bin/gh"

FAILED=0
ok() { printf '  ok  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1" >&2; FAILED=1; }
has() { grep -Fq -- "$1" "$FIXTURE_CAPTURE/notes" && ok "$2" || bad "$2"; }
lacks() { if grep -Fq -- "$1" "$FIXTURE_CAPTURE/notes"; then bad "$2"; else ok "$2"; fi; }
new_case() {
  git init -q --bare "$TMP/$1.git"
  git init -q -b master "$TMP/$1"
  cd "$TMP/$1"
  git remote add origin "$TMP/$1.git"
  printf '%s\n' "$2" > version.md
  export FIXTURE_CURRENT="$2" FIXTURE_CAPTURE="$TMP/$1-capture"
  mkdir "$FIXTURE_CAPTURE"
}
commit_case() {
  git add -A
  git commit -qm "$1"
  git push -q origin master
}
run_release() {
  bash "$RELEASE" --repo fixture/release --ref "$1" --sleep 0 > "$FIXTURE_CAPTURE/output" 2>&1 \
    || { cat "$FIXTURE_CAPTURE/output" >&2; exit 1; }
}

new_case dirty 1.2.3
printf '## 1.2.3 - published\n\nCommitted notes.\n' > CHANGELOG.md
commit_case '1.2.3 - published'
printf '## 1.2.3 - draft\n\nUncommitted notes.\n' > CHANGELOG.md
run_release HEAD
has 'Committed notes.' 'notes come from the release commit'
lacks 'Uncommitted notes.' 'dirty working-tree notes are excluded'

new_case prefix 1.2.3
cat > CHANGELOG.md <<'NOTES'
## 1.2.30 - another version

Prefix collision.

## 1.2.3 - selected

Exact version.

## 1.2.2 - older

Older notes.
NOTES
commit_case '1.2.3 - selected'
run_release HEAD
has 'Exact version.' 'the complete version token is matched'
lacks 'Prefix collision.' '1.2.3 does not select 1.2.30'
lacks 'Older notes.' 'another version ends a section'

new_case repeated 1.2.3
cat > CHANGELOG.md <<'NOTES'
## 1.2.3 - second block

Second block body.

### Validation

Nested validation details.

## 1.2.3 - first block

First block body.

## 1.2.2 - older

Older notes.
NOTES
commit_case '1.2.3 - selected'
run_release HEAD
has 'Second block body.' 'the first matching section is kept'
has 'First block body.' 'every section for a shared version is included'
has '### Validation' 'nested subsection headings are preserved'
has 'Nested validation details.' 'nested subsection bodies are preserved'
lacks 'Older notes.' 'repeated sections do not include another version'

new_case historical 1.2.3
printf '### `1.2.3` — 2026-10-29 — selected\n\nHistorical notes.\n' > CHANGELOG.md
commit_case '1.2.3 - selected'
selected="$(git rev-parse HEAD)"
printf '1.2.4\n' > version.md
printf '### `1.2.3` — rewritten later\n\nLater rewrite.\n' > CHANGELOG.md
commit_case '1.2.4 - later commit'
run_release "$selected"
has 'Historical notes.' 'backticked headings are read at the historical target'
lacks 'Later rewrite.' 'a later HEAD cannot replace historical notes'
[ "$(cat "$FIXTURE_CAPTURE/target")" = "$selected" ] \
  && ok 'the notes and release target use the same commit' || bad 'the target changed'

new_case absent 1.2.3
commit_case '1.2.3 - committed fallback subject'
printf '## 1.2.3 - untracked\n\nLocal-only notes.\n' > CHANGELOG.md
run_release HEAD
has 'committed fallback subject' 'an absent committed changelog falls back to commit subjects'
lacks 'Local-only notes.' 'an untracked changelog is never published'

new_case empty 1.2.3
printf '## 1.2.3 - empty\n\n' > CHANGELOG.md
commit_case 'initial fixture'
run_release HEAD
[ -f "$FIXTURE_CAPTURE/generated" ] \
  && ok 'empty notes without matching subjects use GitHub generation' || bad 'empty notes skipped the final fallback'

exit "$FAILED"
