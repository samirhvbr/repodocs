#!/usr/bin/env bash
# release.sh — every version in version.md gets a git tag named after it and a
# published GitHub Release.
#
# WHY THIS EXISTS: GitHub never infers a version from a commit subject. A repo
# whose history is full of `2.110.161 - …` still shows "No releases published",
# and `git diff 2.110.160..2.110.161` is impossible because neither name exists
# as a ref. The tag is what pins a version number to the exact code it named.
#
# The version is THE FIRST SEMVER IN version.md — not the whole file. Two shapes
# live in this fleet and both must read the same:
#     1.76.108                            (bare, e.g. EOP, SHVIA-WEB, repodocs)
#     # Versão — X\n**Versão atual:** `0.17.1`   (markdown, e.g. the BLUE3-ISP repos)
# That is the rule those repos already document and that config/app.php already
# implements with preg_match('/\d+\.\d+\.\d+/').
#
# Tags carry NO `v` prefix: the tag is byte-for-byte what version.md says.
#
# Idempotent and resumable by construction — anything that already exists is
# skipped, so re-running is free and an interrupted run just continues.
#
#   ./tools/release.sh --dry-run              # print the table, create nothing
#   ./tools/release.sh                        # tag+release the current version
#   ./tools/release.sh --backfill --dry-run   # the whole history, as a table
#   ./tools/release.sh --backfill             # the whole history, for real
#
# Norm: docs/versioning.md · docs/decisions.md ADR-011
set -uo pipefail

MODE=current
DRY=0
REPO=""
SLEEP=0.35          # throttle: ~2.8 req/s, well under GitHub's ceiling
RATE_FLOOR=200      # stop and report rather than exhausting the budget

die() { printf 'release.sh: %s\n' "$1" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --backfill) MODE=backfill ;;
    --current)  MODE=current ;;
    --dry-run|-n) DRY=1 ;;
    --repo) REPO="${2:-}"; shift ;;
    --sleep) SLEEP="${2:-}"; shift ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument '$1' (try --help)" ;;
  esac
  shift
done

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT" || die "cannot cd to repo root"

[ -f version.md ] || die "no version.md at $ROOT — the fleet's version authority is missing"

# --- the version is the FIRST semver in the file, whatever shape it has -------
first_semver() { grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "$1" 2>/dev/null | head -n 1; }

CURRENT="$(first_semver version.md)"
[ -n "$CURRENT" ] || die "version.md holds no X.Y.Z anywhere"

if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)"
fi
[ -n "$REPO" ] || die "cannot determine owner/name — pass --repo owner/name"

BRANCH="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo master)"

# --- release notes ------------------------------------------------------------
# Preference: the CHANGELOG section for this version → the commit subjects that
# carried it → GitHub's own generated notes. EOP has no CHANGELOG.md at all, so
# the fallback is not theoretical.
#
# Two heading shapes exist in this fleet, and both are matched:
#   ## 1.1.0 - título
#   ### `0.17.0` — 2026-08-24 — título
notes_for() {
  local ver="$1" sha="$2" out="$3" body=""
  if [ -f CHANGELOG.md ]; then
    body="$(awk -v ver="$ver" '
      # Returns the heading level (2..4), or 0 for a non-heading line.
      function hlevel(line,   m) {
        if (match(line, /^#{2,4}[ \t]/)) { m = substr(line, 1, RLENGTH); gsub(/[ \t]/, "", m); return length(m) }
        return 0
      }
      # Does this heading name our version? Backticks are stripped because the
      # fleet writes both `## 1.1.0 - x` and "### `0.17.0` - 2026-08-24 - x".
      function is_ours(line,   s) {
        s = line; sub(/^#+[ \t]*/, "", s); gsub(/`/, "", s)
        return index(s, ver) == 1
      }
      { lv = hlevel($0)
        if (!flag) { if (lv && is_ours($0)) { flag = 1; open_lv = lv } ; next }
        # Only a heading at the SAME level or higher ends the section — the
        # entry keeps its own ### subsections, which is where the substance is.
        if (lv && lv <= open_lv) exit
        print }
    ' CHANGELOG.md)"
  fi
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    body="$(git log --format='- %s' --grep="^$(printf '%s' "$ver" | sed 's/\./\\./g') - " "$sha" 2>/dev/null | head -n 40)"
    [ -n "$body" ] && body="## Commits$(printf '\n\n')$body"
  fi
  printf '%s\n' "$body" > "$out"
  [ -s "$out" ] && [ -n "$(tr -d '[:space:]' < "$out")" ]
}

# --- rate limit ---------------------------------------------------------------
rate_left() { gh api rate_limit --jq '.resources.core.remaining' 2>/dev/null || echo 9999; }

# --- one version --------------------------------------------------------------
CREATED=0; SKIPPED=0; FAILED=0
publish() {
  local ver="$1" sha="$2" is_last="$3"
  if gh release view "$ver" --repo "$REPO" >/dev/null 2>&1; then
    printf '  %-14s %s  already published — skipped\n' "$ver" "${sha:0:7}"
    SKIPPED=$((SKIPPED+1)); return 0
  fi
  if [ "$DRY" = "1" ]; then
    printf '  %-14s %s  WOULD CREATE\n' "$ver" "${sha:0:7}"
    CREATED=$((CREATED+1)); return 0
  fi

  local left; left="$(rate_left)"
  if [ "$left" -lt "$RATE_FLOOR" ] 2>/dev/null; then
    printf 'release.sh: STOPPING — only %s API calls left. Re-run later; it resumes.\n' "$left" >&2
    return 9
  fi

  local nf; nf="$(mktemp)"
  local args=(release create "$ver" --repo "$REPO" --target "$sha" --title "$ver")
  if notes_for "$ver" "$sha" "$nf"; then args+=(--notes-file "$nf"); else args+=(--generate-notes); fi
  [ "$is_last" = "1" ] && args+=(--latest)

  if gh "${args[@]}" >/dev/null 2>"$nf.err"; then
    printf '  %-14s %s  published\n' "$ver" "${sha:0:7}"
    CREATED=$((CREATED+1))
  else
    printf '  %-14s %s  FAILED: %s\n' "$ver" "${sha:0:7}" "$(head -n1 "$nf.err")" >&2
    FAILED=$((FAILED+1))
  fi
  rm -f "$nf" "$nf.err"
  sleep "$SLEEP"
}

printf 'repo:    %s\nbranch:  %s\nversion: %s (first semver in version.md)\nmode:    %s%s\n\n' \
  "$REPO" "$BRANCH" "$CURRENT" "$MODE" "$([ "$DRY" = 1 ] && echo '  [DRY RUN — nothing is created]')"

if [ "$MODE" = "current" ]; then
  publish "$CURRENT" "$(git rev-parse HEAD)" 1
else
  # Oldest first, so the newest version is created last and ends up "Latest".
  # For each distinct version, the tag points at the LAST commit that carried
  # it — the finished state of that version, not its first commit. Several
  # commits sharing one version is expected and allowed (ADR-003).
  MAP="$(git log --reverse --format='%H%x09%s' | awk -F'\t' '
    { if (match($2, /^[0-9]+\.[0-9]+\.[0-9]+/)) {
        v = substr($2, RSTART, RLENGTH)
        if (!(v in seen)) { order[++n] = v; seen[v] = 1 }
        last[v] = $1 } }
    END { for (i = 1; i <= n; i++) print order[i] "\t" last[order[i]] }')"
  TOTAL="$(printf '%s\n' "$MAP" | grep -c . || true)"
  printf '%s distinct version(s) in history\n\n' "$TOTAL"
  i=0
  while IFS=$'\t' read -r ver sha; do
    [ -n "$ver" ] || continue
    i=$((i+1))
    publish "$ver" "$sha" "$([ "$i" = "$TOTAL" ] && echo 1 || echo 0)" || break
  done <<< "$MAP"
fi

printf '\ncreated/would-create: %s   skipped: %s   failed: %s\n' "$CREATED" "$SKIPPED" "$FAILED"
[ "$DRY" = 1 ] || git fetch --tags --quiet 2>/dev/null || true
[ "$FAILED" -eq 0 ]
