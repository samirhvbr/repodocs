#!/usr/bin/env bash
# test-fleet.sh — the fixture for `tools/fleet.sh echo`.
#
# It stands up throwaway repositories under a fake owner and runs the real
# script against them, so what is asserted is what a pass over the fleet does:
# which block is stamped, in which language, with which trailers, how many
# commits, and that a second pass writes nothing. Nothing outside a temporary
# directory is touched, no remote is contacted and nothing is pushed.
#
#   ./tools/test-fleet.sh        0 all passed · 1 an assertion failed
#
# Why it exists: ADR-024 puts `tools/fleet.sh` under the rule that a change in its
# behavior arrives with the test that fails when the behavior breaks. This is the
# first one in the tree; until 1.18.0 the fixture lived in a scratch directory.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLEET="$SELF_DIR/fleet.sh"
ECHO_SRC="$(dirname "$SELF_DIR")/templates/echo-blocks"

# A throwaway repository must not inherit the caller's hooks, signing or identity.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=fixture GIT_COMMITTER_EMAIL=fixture@example.invalid
export FLEET_OWNERS="fixowner BLUE3-ISP"
export FLEET_TRAILERS="Co-Authored-By: Fixture <fixture@example.invalid>"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASSED=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { PASSED=$((PASSED + 1)); echo "  ok  $*"; }

make_repo() {   # $1 = dir, $2 = remote url
  git init -q -b master "$1"
  git -C "$1" config remote.origin.url "$2"
  printf '# T\n\nbody\n' > "$1/CLAUDE.md"
  cp "$1/CLAUDE.md" "$1/AGENTS.md"
  printf '0.1.0\n' > "$1/version.md"
  printf '# Changelog\n\n## 0.1.0 - second\n\nbody\n' > "$1/CHANGELOG.md"
  git -C "$1" add -A
  git -C "$1" commit -q -m '0.1.0 - first'
  git -C "$1" commit -q --allow-empty -m '0.1.0 - second'
}

commits() { git -C "$1" rev-list --count HEAD; }

echo "fleet echo fixture"

# --- the templates themselves ------------------------------------------------

# The block is copied into public repositories. Until 1.19.0 that meant it carried
# no address at all; since the owner's decision of 07/10/2026 it carries the
# machine's address, and what makes that tolerable is that the address is RFC 6598
# shared space (100.64.0.0/10), not routable from the internet. Any other address
# appearing in the block would break the one property the decision rests on.
for f in "$ECHO_SRC/CICD-RULE.md" "$ECHO_SRC/CICD-RULE-PT.md"; do
  while IFS= read -r ip; do
    IFS=. read -r a b _ _ <<<"$ip"
    { [ "$a" -eq 100 ] && [ "$b" -ge 64 ] && [ "$b" -le 127 ]; } \
      || fail "$(basename "$f") carries $ip, which is not RFC 6598 shared space"
  done < <(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$f")
  [ "$(grep -c 'CICD-RULE' "$f")" -eq 2 ] || fail "$(basename "$f") must have exactly one opening and one closing marker"
done
ok "the CI block carries no address outside RFC 6598 shared space, in both languages"

# --- a pass limited to the CI block -----------------------------------------

ROOT="$TMP/one"
mkdir -p "$ROOT"
make_repo "$ROOT/en" 'https://github.com/fixowner/en.git'
make_repo "$ROOT/pt" 'https://github.com/BLUE3-ISP/pt.git'
before_en="$(commits "$ROOT/en")"

out="$("$FLEET" echo --root "$ROOT" --block CICD-RULE --apply --no-push 2>&1)" \
  || fail "the limited pass exited non-zero: $out"

grep -q '<!-- CICD-RULE:repodocs -->' "$ROOT/en/CLAUDE.md" || fail "en: CICD-RULE not stamped in CLAUDE.md"
grep -q '<!-- CICD-RULE:repodocs -->' "$ROOT/en/AGENTS.md" || fail "en: CICD-RULE not stamped in AGENTS.md"
grep -q 'Permission is not destination' "$ROOT/en/CLAUDE.md" || fail "en: got the wrong language"
grep -q 'Permissão não é destino' "$ROOT/pt/CLAUDE.md" || fail "pt: the Portuguese variant was not chosen by the owner on origin"
ok "the block is stamped in both files, and the variant follows the owner"

for b in QUEUE-RULE RELEASES-RULE LANGUAGE-RULE COMMIT-RULE; do
  grep -q "<!-- $b:repodocs -->" "$ROOT/en/CLAUDE.md" && fail "--block CICD-RULE also stamped $b"
done
ok "--block CICD-RULE stamps that block and no other"

[ "$(commits "$ROOT/en")" -eq $((before_en + 1)) ] || fail "expected exactly one commit per repository"
[ "$(cat "$ROOT/en/version.md")" = "0.1.1" ] || fail "version.md was not bumped"
git -C "$ROOT/en" log -1 --format=%s | grep -q '^0\.1\.1 - the CI runner rule reaches this repository from repodocs$' \
  || fail "en: the subject does not describe the commit: $(git -C "$ROOT/en" log -1 --format=%s)"
git -C "$ROOT/pt" log -1 --format=%s | grep -q '^0\.1\.1 - a regra do runner de CI chega a este repositório pelo repodocs$' \
  || fail "pt: the subject is not Portuguese or does not describe the commit: $(git -C "$ROOT/pt" log -1 --format=%s)"
grep -q '^## 0\.1\.1 - the CI runner rule' "$ROOT/en/CHANGELOG.md" || fail "the changelog heading is not the commit subject"
ok "one commit, bumped, the subject is the changelog heading, in the repository's language"

git -C "$ROOT/en" log -1 --format=%B | grep -q 'Co-Authored-By: Fixture' || fail "FLEET_TRAILERS was not used"
git -C "$ROOT/en" log -1 --format=%B | grep -q 'Opus 5' && fail "the default trailer leaked into a pass that overrode it"
ok "FLEET_TRAILERS replaces the default trailers"

diff -q <(tail -n +2 "$ROOT/en/CLAUDE.md") <(tail -n +2 "$ROOT/en/AGENTS.md") >/dev/null \
  || fail "the twins differ below the H1 (ADR-007)"
ok "the twins stay byte-identical below the H1"

# --- idempotence -------------------------------------------------------------

before_en="$(commits "$ROOT/en")"
out="$("$FLEET" echo --root "$ROOT" --block CICD-RULE --apply --no-push 2>&1)" || fail "second pass failed: $out"
[ "$(commits "$ROOT/en")" -eq "$before_en" ] || fail "a second pass made a commit"
printf '%s' "$out" | grep -q 'already current' || fail "a second pass did not say it was current"
ok "a second pass writes nothing"

# --- refusals ----------------------------------------------------------------

set +e
"$FLEET" echo --root "$ROOT" --block NOT-A-BLOCK >/dev/null 2>&1; rc_unknown=$?
"$FLEET" hooks --root "$ROOT" --block CICD-RULE >/dev/null 2>&1; rc_hooks=$?
set -e
[ "$rc_unknown" -eq 2 ] || fail "an unknown block must exit 2, got $rc_unknown"
[ "$rc_hooks" -eq 2 ] || fail "--block with hooks must exit 2, got $rc_hooks"
ok "an unknown block, and --block with hooks, are refused rather than stamping nothing"

# --- the default pass carries every block -----------------------------------

ROOT2="$TMP/two"
mkdir -p "$ROOT2"
make_repo "$ROOT2/all" 'https://github.com/fixowner/all.git'
"$FLEET" echo --root "$ROOT2" --apply --no-push >/dev/null 2>&1 || fail "the default pass failed"
for b in QUEUE-RULE RELEASES-RULE LANGUAGE-RULE COMMIT-RULE CICD-RULE; do
  grep -q "<!-- $b:repodocs -->" "$ROOT2/all/CLAUDE.md" || fail "the default pass did not stamp $b"
done
ok "the default pass stamps all five blocks, CICD-RULE included"

# --- the Portuguese set is matched by whole name ------------------------------

# `samirhvbr/blue3-intranet` is in the set; `samirhvbr/blue3-intranet-lscripts`
# is not. Until 1.19.4 a prefix pattern put both in it, and on 23/10/2026 that
# was live: two repositories that left BLUE3-ISP kept getting Portuguese blocks.
ROOT3="$TMP/three"
mkdir -p "$ROOT3"
make_repo "$ROOT3/intranet" 'git@github.com:samirhvbr/blue3-intranet.git'
make_repo "$ROOT3/sibling"  'https://github.com/samirhvbr/blue3-intranet-lscripts.git'
FLEET_OWNERS="samirhvbr BLUE3-ISP" "$FLEET" echo --root "$ROOT3" --apply --no-push >/dev/null 2>&1 \
  || fail "the pass over the name-boundary fixture failed"
grep -q '^## Idioma — este repositório é escrito em português' "$ROOT3/intranet/CLAUDE.md" \
  || fail "samirhvbr/blue3-intranet lost its Portuguese block"
grep -q '^## Language — English (US)' "$ROOT3/sibling/CLAUDE.md" \
  || fail "samirhvbr/blue3-intranet-lscripts was read as blue3-intranet: a prefix match"
ok "the samirhvbr repositories of the Portuguese set are matched whole, not as a prefix"

echo
echo "$PASSED assertions passed."
