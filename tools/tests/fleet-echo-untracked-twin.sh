#!/usr/bin/env bash
# fleet.sh echo — a repository whose AGENTS.md exists on disk but was never
# committed must be SKIPPED, and the pass must leave nothing behind.
#
# Why this test exists: on 07/10/2026 the echo pass selected SAMIRHV, whose
# AGENTS.md is untracked. Stamping made the twins differ (they already did), the
# commit was abandoned, and `rollback_one` ran
# `git checkout -- CLAUDE.md AGENTS.md` — which git refuses as a WHOLE pathspec
# when one path is untracked, restoring neither. The pass left a
# stamped-but-uncommitted CLAUDE.md in that repository, and `2>/dev/null` hid it.
#
# Two things are asserted, because the fix has two halves:
#   1. the repository is skipped, with the reason naming the untracked twin;
#   2. nothing in the working tree changed — in particular CLAUDE.md.
#
# Run: bash tools/tests/fleet-echo-untracked-twin.sh
set -u

REPODOCS="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

fail=0
ok()   { printf '  [ok]     %s\n' "$1"; }
bad()  { printf '  [FALHOU] %s\n' "$1"; fail=1; }

# --- a throwaway fleet of one -------------------------------------------------
git init -q --bare "$T/remotes/alpha.git"
mkdir -p "$T/alpha"; cd "$T/alpha"; git init -q .
git config user.email t@example.com; git config user.name tester
git config url."$T/remotes/".insteadOf "https://github.com/testowner/"
git remote add origin "https://github.com/testowner/alpha.git"

printf '0.1.0\n' > version.md
printf '# alpha\n\nfixture\n' > CLAUDE.md
printf '# Changelog\n\n## 0.1.0 - the fixture is born\n\nbody\n' > CHANGELOG.md
git add version.md CLAUDE.md CHANGELOG.md
git commit -q -m "0.1.0 - the fixture repository is born with its files"
for i in 1 2 3 4; do
  printf '0.1.%s\n' "$i" > version.md
  git commit -q -am "0.1.$i - a compliant subject so the history reads as ours"
done
git branch -M master; git push -q -u origin master
git remote set-head origin master >/dev/null 2>&1

# the defect's precondition: AGENTS.md on disk, never committed
printf '# alpha (agents)\n\nfixture\n' > AGENTS.md
before="$(sha256sum CLAUDE.md | cut -d' ' -f1)"

# --- run the real thing ------------------------------------------------------
out="$(cd "$REPODOCS" && FLEET_OWNERS=testowner bash tools/fleet.sh echo --apply --root "$T" 2>&1)"

printf '%s\n' "$out" | grep -q "alpha.*not tracked" \
  && ok "skipped, and the reason names the untracked twin" \
  || bad "should have been skipped for an untracked twin; got: $(printf '%s' "$out" | grep -i alpha | head -1)"

printf '%s\n' "$out" | grep -qE '^  \+ +alpha' \
  && bad "it was applied — the gate did not hold" \
  || ok "not applied"

after="$(sha256sum "$T/alpha/CLAUDE.md" | cut -d' ' -f1)"
[ "$before" = "$after" ] \
  && ok "CLAUDE.md untouched in the working tree" \
  || bad "CLAUDE.md was left modified — the rollback debris is back"

[ -z "$(git -C "$T/alpha" status --porcelain -- CLAUDE.md)" ] \
  && ok "git reports CLAUDE.md clean" \
  || bad "git reports CLAUDE.md dirty"

echo
[ "$fail" -eq 0 ] && { echo "tudo passou."; exit 0; } || { echo "houve falha."; exit 1; }
