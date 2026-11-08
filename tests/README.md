# Headless verification

`tests/verify.sh` boots this checkout's **real** config in `nvim --headless`,
opens files from `tests/fixture`, and checks behavior you could observe as a
user: startup errors, which plugins are installed, which language servers
attach, what keys are mapped, and what options are set.

## Running it

```sh
tests/verify.sh              # everything
tests/verify.sh servers:     # only tests whose name contains "servers:"
```

It prints `ok` / `FAIL` / `skip` per test, then the failure messages. The exit
code is `0` when nothing failed, `1` when a test failed, `2` on timeout and `3`
when the harness itself crashed. Nvim's stderr is printed only when the run
fails.

It works from any checkout (including a `cw` worktree): the script points
`XDG_CONFIG_HOME` at a temp dir whose `nvim` entry links to the checkout (every
other entry links to your real `~/.config`), so the config under test is the
one next to the script, not `~/.config/nvim`. Plugins, Mason packages and
parsers come from your normal data dir (`~/.local/share/nvim`), and if lazy.nvim
installs a missing plugin during the run it updates the checkout's
`lazy-lock.json`, the same as a normal start would. The run starts inside
`tests/fixture`, the same way you'd start Nvim in a project root.

A server-attach test is **skipped**, not failed, when that server's executable
isn't installed. The skip message names the binary to install with
`:MasonInstall`. Servers whose config builds `cmd` in a function name no binary
up front, so they can't be skipped this way.

## Layout

| Path                 | What it is                                                           |
| -------------------- | -------------------------------------------------------------------- |
| `verify.sh`          | The one command. Sets up the config home and runs Nvim.              |
| `verify/prelude.lua` | Runs before the config (`--cmd`). Records ERROR-level notifications. |
| `verify/run.lua`     | Boots, loads every spec, runs it, reports, exits.                    |
| `verify/harness.lua` | The helpers specs use (below).                                       |
| `verify/specs/*.lua` | The tests, one file per area. Loaded alphabetically.                 |
| `fixture/`           | A small project: one file per filetype the config routes.            |

## Writing tests

A spec file gets the harness as `...`:

```lua
local h = ...

h.test('servers: .ts attaches tsc + eslint', function()
  h.expect_servers('src/index.ts', { includes = { 'tsc', 'eslint' }, excludes = { 'ts_ls' } })
end)
```

Name tests `<area>: <behavior>` so the filter argument can pick an area.
Assert behavior, never how a plugin spec or module is laid out.

| Helper                                          | Use it for                                                                                                                          |
| ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `h.test(name, fn)`                              | Register a test.                                                                                                                    |
| `h.ok(cond, msg)` / `h.eq(a, b, what)`          | Assert. A failure reports the spec file and line.                                                                                   |
| `h.skip(reason)`                                | End a test as skipped.                                                                                                              |
| `h.startup_errors()`                            | Error lines in `:messages` + ERROR notifications, captured right after boot.                                                        |
| `h.checkhealth_errors(section)`                 | `ERROR` lines from `:checkhealth <section>`.                                                                                        |
| `h.plugin(name)`                                | The lazy.nvim registry entry for a plugin (loaded or not), or `nil`.                                                                |
| `h.open(rel)`                                   | Edit a fixture file; returns the buffer.                                                                                            |
| `h.servers(buf)`                                | Sorted names of the clients attached to a buffer.                                                                                   |
| `h.expect_servers(rel, { includes, excludes })` | Open a fixture file, wait for `includes` to attach, fail on missing or `excludes`. Skips when an `includes` binary isn't installed. |
| `h.map(mode, lhs, buf?)`                        | `maparg()` details for whatever answers `lhs` (buffer-local maps count when `buf` is given), or `nil`.                              |
| `h.opt(name, buf?)`                             | An option's global value, or its value in `buf` (window options read from its window).                                              |

## Fixture

`fixture/` has `src/index.ts` (with `eslint.config.js`), `src/App.vue`,
`src/styles.css`, `data/settings.json`, `data/settings.yaml`, `notes.md` and
`lua/sample.lua`, plus `src/messy.ts`. That file is intentionally unformatted,
with an unused import and a fixable ESLint issue, for the fix-on-save checks.
Don't format it.

ESLint needs its packages to lint (`npm install` inside `fixture/`, and
`node_modules` is gitignored). The `eslint` server attaches without them.
