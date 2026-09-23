#!/bin/sh
set -eu

EXPECTED_REPO='https://github.com/aweigit/freej2me-miyoomini.git'
EXPECTED_COMMIT='ca11dfe8ea1cc273d92460f9a83bbf192023fa63'
SUBMODULE='upstream/freej2me-miyoomini'

fail() { echo "CANONICAL_GATE=FAIL: $*" >&2; exit 1; }

[ -d "$SUBMODULE/.git" ] || [ -f "$SUBMODULE/.git" ] || fail "canonical submodule is not initialized"

actual_commit=$(git -C "$SUBMODULE" rev-parse HEAD)
[ "$actual_commit" = "$EXPECTED_COMMIT" ] || fail "commit $actual_commit != $EXPECTED_COMMIT"

actual_url=$(git config -f .gitmodules --get submodule.upstream/freej2me-miyoomini.url)
[ "$actual_url" = "$EXPECTED_REPO" ] || fail "repo $actual_url != $EXPECTED_REPO"

if [ -n "$(git -C "$SUBMODULE" status --porcelain --untracked-files=all)" ]; then
  fail "canonical working tree is dirty"
fi

if [ -n "$(git diff --submodule=short -- "$SUBMODULE")" ]; then
  fail "gitlink differs from pinned canonical commit"
fi

echo "CANONICAL_GATE=PASS"
echo "AWEIGIT_REPO=aweigit/freej2me-miyoomini"
echo "AWEIGIT_COMMIT=$actual_commit"
