# Headless verification

`tests/verify.sh` boots this checkout's **real** config in `nvim --headless`,
opens files from `tests/fixture`, and checks behavior you could observe as a
user: startup errors, which plugins are installed, which language servers
attach, what keys are mapped, and what options are set.

## Running it

```sh
tests/check.sh               # stylua, then every test: the one check command
tests/check.sh servers:      # stylua, then only tests whose name contains "servers:"
tests/check.sh --lint-only   # stylua only
tests/verify.sh [pattern]    # the harness alone
```

`check.sh` finds Mason's stylua, which is on PATH only inside Nvim. The
pre-commit hook in `.githooks/` runs it whenever a commit touches the config or
`tests/` (stylua alone for other Lua). Enable it once per clone with
`git config core.hooksPath .githooks`.

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

The run is signed out of everything. `verify.sh` unsets every env var whose
name contains `TOKEN`, `SECRET` or `API_KEY` or starts with `GITHUB_`, `GH_` or
`COPILOT_`, and leaves the login dirs (`github-copilot`, `gh`) out of the temp
config home. The `startup:` checks fail if either leaks through. A test that
needs one of those dirs or variables has to provide its own throwaway copy.

A server-attach test is **skipped**, not failed, when that server's executable
isn't installed. The skip message names the binary to install with
`:MasonInstall`. Servers whose config builds `cmd` in a function name no binary
up front, so they can't be skipped this way.

The `diagnostics:` tests need the network: jsonls and yamlls download the
schema they validate against. Offline they fail, not skip.

## Layout

| Path                 | What it is                                                           |
| -------------------- | -------------------------------------------------------------------- |
| `check.sh`           | The one check command: stylua, then `verify.sh`.                     |
| `verify.sh`          | The harness. Sets up a signed-out config home and runs Nvim.         |
| `verify/prelude.lua` | Runs before the config (`--cmd`). Records ERROR-level notifications. |
| `verify/run.lua`     | Boots, loads every spec, runs it, reports, exits.                    |
| `verify/harness.lua` | The helpers specs use (below).                                       |
| `verify/specs/*.lua` | The tests, one file per area. Loaded alphabetically.                 |
| `verify/expected/`   | Hand-written files a saved fixture must match (the `save:` tests).   |
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

| Helper                                          | Use it for                                                                                                                                                |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `h.test(name, fn)`                              | Register a test.                                                                                                                                          |
| `h.ok(cond, msg)` / `h.eq(a, b, what)`          | Assert. A failure reports the spec file and line.                                                                                                         |
| `h.skip(reason)`                                | End a test as skipped.                                                                                                                                    |
| `h.startup_errors()`                            | Error lines in `:messages` + ERROR notifications, captured right after boot.                                                                              |
| `h.checkhealth_errors(section)`                 | `ERROR` lines from `:checkhealth <section>`.                                                                                                              |
| `h.checkhealth_problems(section)`               | `WARNING`/`ERROR` items from `:checkhealth <section>`, each `{ level, text, detail }` (`detail`: the indented lines, e.g. a stack trace).                 |
| `h.plugin(name)`                                | The lazy.nvim registry entry for a plugin (loaded or not), or `nil`.                                                                                      |
| `h.open(rel)`                                   | Edit a fixture file (or an absolute path); returns the buffer.                                                                                            |
| `h.copy_fixture(rel)`                           | Copy a fixture file into a temp dir with no `.dir` in its path; returns the copy's path. yamlls applies no schema under a dot-directory.                  |
| `h.sibling_copy(rel)`                           | Copy a fixture file next to itself as `<name>.saved.<ext>`, so saving it runs in the fixture project; returns its path. Deleted after the test.          |
| `h.expected(name)`                              | The lines of `verify/expected/<name>`, to compare a saved file with.                                                                                      |
| `h.servers(buf)`                                | Sorted names of the clients attached to a buffer.                                                                                                         |
| `h.expect_servers(rel, { includes, excludes })` | Open a fixture file (or an absolute path), wait for `includes` to attach, fail on missing or `excludes`. Skips when an `includes` binary isn't installed. |
| `h.position_of(buf, text)`                      | The LSP position (0-based) of the first occurrence of `text` in `buf`, so specs don't hardcode line/column.                                               |
| `h.hover_until(buf, server, pos, done)`         | Hover from one attached server, re-asked one request at a time until `done(text)` holds; returns `ok, text`. Use it for every hover.                      |
| `h.map(mode, lhs, buf?)`                        | `maparg()` details for whatever answers `lhs` (buffer-local maps count when `buf` is given), or `nil`.                                                    |
| `h.expect_map(mode, lhs, desc, buf?)`           | Assert `lhs` is mapped in `mode` with description `desc` (resolved from `buf` when given); returns the mapping.                                           |
| `h.key_group(lhs, mode?)`                       | The which-key group label at `lhs` (e.g. `'[S]earch'`), or `nil`. Counts a declared group that has no keys under it yet.                                |
| `h.opt(name, buf?)`                             | An option's global value, or its value in `buf` (window options read from its window).                                                                    |

`h.expect_servers` watches for servers that shouldn't attach until the buffer's
servers have held still for 1.5s. It does that once per buffer, so checking an
already-settled buffer again doesn't wait. `h.open` leaves a file that is already
in the current window alone: `:edit` would re-read it, and its servers would
detach and attach again.

## Fixture

`fixture/` has `src/index.ts` (with `eslint.config.js`), `src/App.vue`,
`src/styles.css` (with `.stylelintrc.json`, which has no rules: `stylelint_lsp`
attaches only where a Stylelint config exists), `src/index.html` and
`src/Page.astro` (markup with a `<style>` block, which `stylelint_lsp` must not
attach to), `data/settings.json`, `data/settings.yaml`, `notes.md` and
`lua/sample.lua`, plus `src/messy.ts` and `lua/messy.lua`. Those two are
intentionally unformatted (`messy.ts` also has an unused import and a fixable
ESLint issue) for the `save:` checks, which save a `h.sibling_copy` and compare
it with `verify/expected/`. Don't format them; `.styluaignore` keeps
`stylua --check` off `messy.lua`. In `src/index.ts`,
`greet(visitor)` passes a variable on purpose: the hints check needs a
non-literal argument, so don't change it to a literal.
In `src/App.vue`, `label` is a string literal on purpose: the Vue-plugin check
hovers it and expects `"Clicked"`, a type that doesn't need `vue` installed.
`src/folds.ts` opens with two import lines: the folding check expects them
closed after open, so keep at least two imports at the top.
`stylua.toml` does two jobs: it is the stylua config the `save:` check formats
`lua/messy.lua` by, and it is the folding checks' "parser, no server" file. No
server is configured for TOML but nvim-treesitter has its parser, so it must
fold with treesitter. Keep it TOML, and don't route a TOML server in without
moving that check to another such file.
`data/vercel.json` and `data/compose.yaml` each carry a top-level key their
SchemaStore schema forbids (`notARealOption`), for the schema-diagnostic checks.
Keep their file names: SchemaStore picks the schema by name.

ESLint and the Astro server need the fixture's packages. `node_modules` is
gitignored; `verify.sh` runs `npm ci` from the committed `package-lock.json`
when it's missing (a fresh clone or worktree), and stops if that fails. To
change a package, edit `package.json`, run `npm install` in `fixture/`, and
commit both files.
