#!/usr/bin/env bash
# Headless verification harness: boots this checkout's real config against
# tests/fixture and runs every spec in tests/verify/specs. See tests/README.md.
#
#   tests/verify.sh            run everything
#   tests/verify.sh <pattern>  run only tests whose name contains <pattern>
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Boot the config from this checkout (it may be a worktree, not ~/.config/nvim):
# point XDG_CONFIG_HOME at a temp dir whose `nvim` entry links here. Every other
# entry links to the real config home, so the servers and tools Nvim spawns
# (Copilot's login, git, ...) still find their own config.
REAL_XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_TMP="$(mktemp -d)"
trap 'rm -rf "$XDG_TMP"' EXIT
for entry in "$REAL_XDG"/* "$REAL_XDG"/.[!.]*; do
  [ -e "$entry" ] || continue
  [ "$(basename "$entry")" = nvim ] && continue
  ln -s "$entry" "$XDG_TMP/$(basename "$entry")"
done
ln -s "$REPO" "$XDG_TMP/nvim"

export VERIFY_REPO="$REPO"
export VERIFY_FILTER="${1:-}"

# Nvim's own stderr (startup errors, progress chatter) goes to a log that is
# shown only when the run fails; the report itself is on stdout.
STDERR_LOG="$XDG_TMP/stderr.log"

cd "$REPO/tests/fixture"
status=0
XDG_CONFIG_HOME="$XDG_TMP" nvim --headless -n -i NONE \
  --cmd "lua dofile(vim.env.VERIFY_REPO .. '/tests/verify/prelude.lua')" \
  -c "lua local ok, err = pcall(dofile, vim.env.VERIFY_REPO .. '/tests/verify/run.lua')
      if not ok then io.stdout:write('HARNESS ERROR: ' .. tostring(err) .. '\n'); vim.cmd 'cquit 3' end" \
  2>"$STDERR_LOG" || status=$?

if [ "$status" -ne 0 ] && [ -s "$STDERR_LOG" ]; then
  printf '\n--- nvim stderr ---\n'
  cat "$STDERR_LOG"
  echo
fi
exit "$status"
