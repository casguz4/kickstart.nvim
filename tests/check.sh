#!/usr/bin/env bash
# The repo's one check command: stylua over the repo, then the headless harness.
# The pre-commit hook runs this too.
#
#   tests/check.sh              stylua + every harness test
#   tests/check.sh <pattern>    stylua + harness tests whose name contains <pattern>
#   tests/check.sh --lint-only  stylua only
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# stylua comes from Mason, which puts it on PATH only inside Nvim.
STYLUA="$(command -v stylua || echo "${MASON:-$HOME/.local/share/nvim/mason}/bin/stylua")"
if [ ! -x "$STYLUA" ]; then
  echo "check: stylua not found; install it with :MasonInstall stylua" >&2
  exit 1
fi
if ! (cd "$REPO" && "$STYLUA" --check --respect-ignores .); then
  echo "check: stylua found unformatted files (above); run stylua on them" >&2
  exit 1
fi

[ "${1:-}" = --lint-only ] && exit 0
exec "$REPO/tests/verify.sh" "$@"
