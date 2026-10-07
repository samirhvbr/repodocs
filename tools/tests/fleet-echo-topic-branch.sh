#!/usr/bin/env bash
# fleet.sh echo — a checkout sitting on a topic branch must be SKIPPED, and a
# checkout sitting on its own default branch must still be selected even when
# that default is not `master`.
#
# Why this test exists: on 07/10/2026 the echo pass stamped 44 repositories and
# two of them were not on their default branch. The block was committed and
# pushed to a topic branch, the default branch never got it, and `check` — which
# reads the working tree — kept reporting the block as present. A silent
# false-green.
#
# The second case is the one that makes the fix non-trivial: the gate compares
# against the REMOTE's default, not against the string "master", because
# `blue3-intranet-ntheme` works on `dev` by written decision.
#
# Run: bash tools/tests/fleet-echo-topic-branch.sh
set -u

REPODOCS="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

fail=0
ok()  { printf '  [ok]     %s\n' "$1"; }
bad() { printf '  [FALHOU] %s\n' "$1"; fail=1; }

# $1 = name, $2 = default branch, $3 = branch to leave checked out
mk() {
  local n="$1" def="$2" head="$3"
  git init -q --bare "$T/remotes/$n.git"
  mkdir -p "$T/$n"; cd "$T/$n"; git init -q .
  git config user.email t@example.com; git config user.name tester
  git config url."$T/remotes/".insteadOf "https://github.com/testowner/"
  git remote add origin "https://github.com/testowner/$n.git"
  printf '0.1.0\n' > version.md
  printf '# %s\n\nfixture\n' "$n" > CLAUDE.md
  printf '# %s (agents)\n\nfixture\n' "$n" > AGENTS.md
  printf '# Changelog\n\n## 0.1.0 - born\n\nbody\n' > CHANGELOG.md
  git add -A; git commit -q -m "0.1.0 - the fixture repository is born with its files"
  local i
  for i in 1 2 3 4; do
    printf '0.1.%s\n' "$i" > version.md
    git commit -q -am "0.1.$i - a compliant subject so the history reads as ours"
  done
  git branch -M "$def"; git push -q -u origin "$def"
  git symbolic-ref "refs/remotes/origin/HEAD" "refs/remotes/origin/$def"
  if [ "$head" != "$def" ]; then
    git checkout -q -b "$head"; git push -q -u origin "$head"
  fi
  cd "$T"
}

mk topico  master  feature/algo     # on a topic branch -> must be skipped
mk propria dev     dev              # its own default is `dev` -> must be selected

out="$(cd "$REPODOCS" && FLEET_OWNERS=testowner bash tools/fleet.sh echo --apply --root "$T" 2>&1)"

printf '%s\n' "$out" | grep -q "topico.*not the default branch" \
  && ok "topic branch skipped, reason names the branch" \
  || bad "topic branch was not skipped: $(printf '%s' "$out" | grep -i topico | head -1)"

printf '%s\n' "$out" | grep -qE '^  \+ +topico' \
  && bad "topic branch was stamped — the gate did not hold" \
  || ok "topic branch not stamped"

printf '%s\n' "$out" | grep -qE '^  \+ +propria' \
  && ok "a repository on its own non-master default is still stamped" \
  || bad "a default of 'dev' was treated as a topic branch: $(printf '%s' "$out" | grep -i propria | head -1)"

# `check` reads the working tree, so on a topic branch every one of its findings
# is about that branch. It has to say so, or a block present only there reads as
# present — which is exactly how this went unnoticed.
chk="$(cd "$REPODOCS" && FLEET_OWNERS=testowner bash tools/fleet.sh check --root "$T" 2>&1)"
printf '%s\n' "$chk" | grep -q "not 'master' — every finding above is about that branch" \
  && ok "check says its findings are about the branch, not the repository" \
  || bad "check reported on a topic branch without saying so"
# `propria` does carry a finding — its default is `dev`, which ADR-015 flags
# unless written down — so the assertion is narrower than "no findings": it must
# not carry the branch-MISMATCH finding, because it is on its own default.
printf '%s\n' "$chk" | sed -n '/^  ---   propria/,/^  \(ok\|---\)/p' \
  | grep -q "every finding above is about that branch" \
  && bad "check called a repository on its own default a topic branch" \
  || ok "a repository on its own default is not called a topic branch"

echo
[ "$fail" -eq 0 ] && { echo "tudo passou."; exit 0; } || { echo "houve falha."; exit 1; }
