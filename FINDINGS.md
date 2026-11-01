# Neovim 0.11.5 → 0.12 breaking changes & deprecations hitting this config

Ticket: casguz4/kickstart.nvim#5 (map #4). Target: Neovim **0.12.6** (latest stable, the Homebrew bottle).
Scope: `init.lua`, `lua/custom/**`, `lua/kickstart/**`, `lsp/*.lua` at commit `41379be`.

Method: I read every in-scope file and compared each API it uses against the official 0.12 docs
([`news.txt` @ v0.12.6][news], [`deprecated.txt` @ v0.12.6][depr]) and against the runtime source at
tags `v0.12.6` and `v0.11.5`. The source check matters because the docs list deprecations without
saying which ones print a warning. Neovim prints a warning only when the removal version is the
next minor release ([`vim.deprecate()` source][deprecate-src]). So on 0.12, anything due for removal
in `0.13` warns, and anything due in `0.14` or `2.0` only shows up in `:checkhealth vim.deprecated`.

## TL;DR

| # | File:line | Severity on 0.12 | What happens | Fix |
|---|-----------|------------------|--------------|-----|
| 1 | `lsp/tsgo.lua:13-15` (+ `lua/custom/plugins/lspconfig.lua:224`) | **Breaks** | If no root file is found, `return` gives `nil`. 0.12 **throws** `lsp/tsgo.lua: not a table`, and `vim.lsp.enable{...}` now resolves every config up front and **aborts the whole call** on the first error. Result: **no LSP server starts** in that session (lua_ls, gopls, …), not only tsgo. `TSGOPATH` is set on this machine, so this code path runs. | Always return a table from `lsp/tsgo.lua`. Use `root_markers = {...}` (or a `root_dir = function(bufnr, on_dir)`) instead of the `vim.fs.find`-at-load-time + bare `return`. |
| 2 | `lua/custom/plugins/lspconfig.lua:172` | **Warns** (removed in 0.13) | `client.supports_method '...'` (dot call) is hard-deprecated: a one-time "client.supports_method is deprecated" message. It still works. | `client:supports_method('textDocument/inlayHint')` (works on 0.11 too) |
| 3 | `lua/custom/plugins/lspconfig.lua:166-167` | **Warns** (removed in 0.13) | `vim.diagnostic.goto_prev` / `goto_next` are hard-deprecated: a one-time warning the first time you press `[d`/`]d`. | Delete both maps (nvim ships `[d`/`]d` defaults) and keep the float through config, or map `vim.diagnostic.jump({count=±1, float=true})`. See §3. |
| 4 | `init.lua:159` (comment at `:154`) | Silent (soft-deprecated, removal 2.0) | `vim.highlight.on_yank()` still works. It only shows in `:checkhealth vim.deprecated`. | `vim.hl.on_yank()` (works on 0.11 too) |
| 5 | `lua/custom/plugins/lspconfig.lua:156`, `lua/kickstart/plugins/gitsigns.lua:14` | Silent (doc-only deprecation) | The `buffer` key in `vim.keymap.set` opts was renamed to `buf`. 0.12 has no runtime warning. Source says "soft-deprecate in 0.13, remove in 0.15". | `buf = bufnr`, but **only after** you're on 0.12 (`buf` doesn't exist in 0.11.5). |
| 6 | `init.lua:678` | Behaviour (default you override) | The 0.12 `'diffopt'` default adds `indent-heuristic,inline:char` (and kept `linematch:40`). Your hard-coded string drops all three. | Optional: `vim.opt.diffopt:append { 'indent-heuristic', 'inline:char', 'linematch:40' }` or a new full string. |
| 7 | `lua/custom/plugins/lspconfig.lua:162` | Behaviour (pre-existing, slightly worse) | Your buffer-local `gr` map overlaps the default `grn/gra/grr/gri/grt` maps, and 0.12 adds **`grx`** (codelens run). `gr` still waits `timeoutlen` (300 ms) before running. | Optional: drop the custom `gr` and use the default `grr`, or add `nowait = true`. |
| 8 | `init.lua:166`, `lua/kickstart/health.lua:46` | None | `(vim.uv or vim.loop)`: `vim.loop` is deprecated (0.10), but the `or` never reaches it. | Optional cleanup: `vim.uv`. |

Nothing else in scope hits a 0.12 breaking change: the rest of the API surface is unchanged and
in use (see "Checked, no impact").

---

## 1. `lsp/tsgo.lua` returning `nil`: hard error that disables all LSP (BREAKS)

Code:

```lua
-- lsp/tsgo.lua:9-15
local paths = vim.fs.find(root_files, { stop = vim.env.HOME })
local root_dir = vim.fs.dirname(paths[1])
if root_dir == nil then
  return            -- module returns nil
end
```

**0.11.5 behaviour:** a non-table `lsp/*.lua` was logged and ignored:
`log.warn(('%s does not return a table, ignoring'):format(v))`
([0.11.5 lsp.lua L421-L428][lsp-0115]).

**0.12 behaviour:** it raises an error: `error(('%s: not a table'):format(v))`
([0.12.6 lsp.lua L338-L349][lsp-0126-load]). The change came from
[neovim#37508 "fix(lsp): raise error when lsp config is invalid type"][pr37508].

0.12 also resolves configs at `vim.lsp.enable()` time and does so all-or-nothing:

> "Check for errors, and abort with no side-effects if there is one. … Raise error if
> `lsp.config[nm]` raises an error, instead of waiting for the error to be triggered by
> `lsp_enable_callback()`." ([0.12.6 lsp.lua L614-L634][lsp-0126-enable])

So when `TSGOPATH` is set (it is on this machine), `ts_server == 'tsgo'` (`lspconfig.lua:222`).
Then `vim.lsp.enable { ... ts_server ... }` (`lspconfig.lua:224-239`) throws inside the lazy.nvim
`config` function, and **none** of the 14 servers get enabled.

When does it trigger? `vim.fs.find` without `upward = true` searches **downward, recursively, from
the cwd** ([fs.lua L266-L300][fsfind]). `stop` only applies to the upward walk. So nvim started in a
directory with no `tsconfig*.json`/`jsconfig.json`/`package.json`/`.git` anywhere below it (for
example a scratch dir, `/tmp`, or a fresh folder) gives `nil`, then the error, then no LSP. A side
effect on both versions: started from `~`, this recursive scan crawls your home directory at startup.

**0.12-native replacement (keeps tsgo as the sole TS server, works on 0.11 too):**

```lua
---@type vim.lsp.Config
return {
  cmd = { vim.env.TSGOPATH .. '/built/local/tsgo', 'lsp', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { 'tsconfig.base.json', 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  -- 0.12 also supports priority groups, e.g. { { 'tsconfig.json', 'jsconfig.json' }, 'package.json', '.git' }
  -- and `workspace_required = true` (new ClientConfig field) to refuse to start without a root.
}
```

`root_markers` priority groups and `workspace_required` are listed under 0.12 LSP features
([news.txt "LSP" section][news-lsp]). `root_markers` resolves per buffer, while the current
`root_dir` string is frozen to whatever the cwd scan found at load time.

## 2. `client.supports_method` dot-call (WARNS)

`lua/custom/plugins/lspconfig.lua:172`: `client.supports_method 'textDocument/inlayHint'`

- Listed in [`deprecated-0.11`][depr-011]: "`client.supports_method()` Use |Client:supports_method()| instead."
- Source: Client methods are wrapped. If the first arg isn't the client,
  `vim.deprecate('client.' .. name, 'client:' .. name, '0.13')` runs and the call is forwarded
  ([0.12.6 client.lua L256-L268][client-wrap]). The removal version is `0.13`, so on 0.12 it is
  **hard-deprecated**: you get a one-time message. On 0.11.5 the same call was silent ([0.11.5 client.lua L241][client-0115]).
- Fix: `client:supports_method('textDocument/inlayHint')`. You can apply it now; it works on 0.11.

## 3. `vim.diagnostic.goto_prev` / `goto_next` (WARNS)

`lua/custom/plugins/lspconfig.lua:166-167`

- Listed in [`deprecated-0.11`][depr-011]: "Use |vim.diagnostic.jump()| with `{count=1, float=true}` instead."
- Source: `vim.deprecate('vim.diagnostic.goto_prev()', 'vim.diagnostic.jump()', '0.13')`
  ([0.12.6 diagnostic.lua L1560-L1567][diag-goto]). Hard-deprecated on 0.12, removed in 0.13.
- Nuance: 0.12 also deprecates the `float` option of `jump()` in favour of `on_jump`
  ([`deprecated-0.12`][depr-012], removal `0.14`, so silent on 0.12; [diagnostic.lua L1235-L1236][diag-float]).
  `on_jump` **does not exist in 0.11.5**.
- Neovim already maps `]d`/`[d` to `vim.diagnostic.jump({count=±v:count1})` by default
  ([defaults.lua L263-L270][defaults-d]). Your buffer-local maps only add the auto-opened float.

Fix options:
- **Works on both 0.11 and 0.12:**
  `map('n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, ...)` (and `count = 1` for `]d`).
- **0.12-native, after upgrading (fewer lines):** delete both maps and add this to the existing
  `vim.diagnostic.config` (`lspconfig.lua:131`):
  ```lua
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false }
    end,
  },
  ```
  (`vim.diagnostic.Opts.Jump.on_jump` is the default `on_jump` for `jump()`, [diagnostic.lua L330-L332][diag-optsjump].)

## 4. `vim.highlight` → `vim.hl` (silent)

`init.lua:159` `vim.highlight.on_yank()` (and the `:help vim.highlight.on_yank()` comment at `:154`).

- Listed in [`deprecated-0.11`][depr-011]: "*vim.highlight* Renamed to |vim.hl|."
- Source: `vim.highlight = vim._defer_deprecated_module('vim.highlight', 'vim.hl')`
  ([editor.lua L1313][hl-shim]). The shim calls `vim.deprecate(..., '2.0.0')` ([shared.lua L1481-L1498][defer-shim]).
  Major 2 > 0, so there is **no warning**; it only shows in `:checkhealth vim.deprecated`.
- Fix: `vim.hl.on_yank()`. Safe to do now.

## 5. `vim.keymap.set` opts `buffer` → `buf` (silent, doc-only)

`lua/custom/plugins/lspconfig.lua:156` (`{ buffer = bufnr, ... }`),
`lua/kickstart/plugins/gitsigns.lua:14` (`opts.buffer = bufnr`).

- Listed in [`deprecated-0.12`][depr-012]: "'buffer' in `vim.keymap.set.Opts` and `vim.keymap.del.Opts` Renamed to 'buf'".
- Source: still accepted with no warning: `-- TODO(skewb1k): soft-deprecate 'buffer' option in 0.13, remove in 0.15.`
  ([keymap.lua L88-L93][keymap-buf]).
- `buf` is **not** recognised by 0.11.5's `vim.keymap.set`, so change this only after you're on 0.12.
- The same rename applies to `nvim_create_autocmd`/`nvim_exec_autocmds`/... (`buffer` → `buf`)
  ([news.txt "CHANGED FEATURES"][news-changed]). The config never passes `buffer` to those, so no hit.

## 6. `'diffopt'` default changed (behaviour)

`init.lua:678`: `vim.opt.diffopt = 'internal,filler,closeoff,hiddenoff,algorithm:patience'`

- 0.12 default: `"internal,filler,closeoff,indent-heuristic,inline:char,linematch:40"`
  ([options.txt L2191][diffopt]; news: "'diffopt' default value now includes 'indent-heuristic' and 'inline:char'" [news.txt L141][news-defaults]).
- 0.11.5 default was `"internal,filler,closeoff,linematch:40"`. Your override already dropped
  `linematch:40`, and it now also skips the two new improvements. It doesn't break anything; this
  is a free upgrade you're opting out of.

## 7. New default `grx` mapping vs. your buffer-local `gr` (behaviour)

`lua/custom/plugins/lspconfig.lua:162`: `map('n', 'gr', vim.lsp.buf.references, ...)`

- 0.12 adds `grx` → `vim.lsp.codelens.run()` ([news.txt L150-L152][news-defaults]; [defaults.lua L212][defaults-grx]).
  `grn/gra/grr/gri/grt` already existed in 0.11.5.
- Because a longer global `gr*` mapping exists, Nvim waits `timeoutlen` (300 ms here) after `gr`
  before firing your mapping (`:h map-<nowait>`). That was already true on 0.11; 0.12 adds one more
  overlapping map. Options: use the built-in `grr` and drop the custom `gr`, or pass `nowait = true`.

## 8. Other changed defaults: checked, negligible for this config

- **Markdown treesitter highlighting is on by default** ([news.txt L154][news-defaults]). Your
  `FileType` autocmd also calls `vim.treesitter.start` (`init.lua:621`). That's redundant for
  markdown but harmless.
- **`'smartcase'` now applies to completion filtering** ([news.txt L470][news-changed]). You set
  `ignorecase`+`smartcase` (`init.lua:46-47`). blink.cmp does its own matching, so this only affects
  built-in `ins-completion`.
- **Default `'statusline'`** now shows diagnostics/progress. mini.statusline overrides it (`init.lua:539-549`), so no effect.
- **`'shada'` excludes `/tmp/` and `/private/`** ([news.txt L153][news-defaults]). Files under
  `/private/tmp` (macOS `$TMPDIR`) no longer show in the dashboard's "Recent Files" (`FzfLua oldfiles`).
- **`i_CTRL-R` inserts registers literally** ([news.txt L38-L40][news]). This is a typing-behaviour change; no config code depends on it.
- **`'shelltemp'` defaults to false** ([news.txt "OPTIONS"][news]). `vim.fn.system { 'git', 'clone', ... }` (`init.lua:168`) sends no stdin, so it's unaffected.

## Checked, no impact

Each of these is used in scope and is unchanged in 0.12, or the 0.12 change doesn't touch how it's used here:

- `pcall(vim.treesitter.start, args.buf)` (`init.lua:621`): 0.12 changed `get_parser()` to return
  `nil` instead of throwing ([news.txt "REMOVED FEATURES"][news]), but `start()` still does
  `assert(M.get_parser(buf, lang))` ([treesitter.lua L450-L462][ts-start]). It still throws without a parser, so the `pcall` guard still works.
- `vim.treesitter.language.register('json', 'jsonc')`, `vim.lsp.config('*', ...)`, `vim.lsp.config(name, ...)`,
  `vim.lsp.enable{...}` (apart from #1), `vim.lsp.inlay_hint.enable(true, {bufnr})`, `vim.lsp.get_client_by_id`,
  `vim.lsp.protocol.make_client_capabilities`, `vim.diagnostic.config{ signs = { text = ... } }`
  (the 0.12 diagnostic breaking changes cover `:sign-define`, `disable()`, legacy `enable()` and
  `Status.format`; none are used), `vim.diagnostic.setloclist`, `vim.diagnostic.open_float`,
  `vim.health.{start,ok,warn,error,info}`, `vim.version.ge`, `vim.iter`, `vim.tbl_contains`,
  `vim.tbl_deep_extend`, `vim.opt*`, `nvim_set_keymap`, `nvim_exec_autocmds('UIEnter', {group=...})`,
  `client.workspace_folders` (`lsp/lua_ls.lua:16`).
- 0.12 LSP breaking items (`vim.NIL` for JSON null, `semantic_tokens.start/stop` → `enable`,
  `attached_buffers[buf]` value type, `vim.lsp.log.set_format_func` args): none are used.
- `vim.diff` → `vim.text.diff`, `ui-messages` event changes, `tohtml` opt-in, `shellmenu` removal: none are used.
- `vim.fn.sign_define` in `lua/{custom,kickstart}/plugins/debug.lua:126-135` is commented out, and
  it's DAP signs, not diagnostic signs.

## Adjacent (not Neovim core, flagged for other tickets)

These are plugin-level issues that turned up while reading. They aren't caused by 0.12, and I
didn't research them further:

- `lua/custom/plugins/dap-js.lua:18,32`: `require('mason-registry').get_package(...):get_install_path()`.
  `Package:get_install_path()` was removed in mason.nvim v2, independent of the Neovim version. The
  lockfile pins mason.nvim `44d1e90`, so verify it there.
- `lua/custom/plugins/lspconfig.lua:238`: `'volar'` (nvim-lspconfig renamed it to `vue_ls`) and
  `lspconfig.lua:17` installs `typescript-language-server` although tsgo is the sole TS server.
- `lua/custom/plugins/debug.lua` and `lua/kickstart/plugins/debug.lua` both define `mfussenegger/nvim-dap`
  with `williamboman/mason.nvim` (old org name) alongside `mason-org/mason.nvim` in `lspconfig.lua:99`.

## Suggested order

1. **Before upgrading (works on both 0.11.5 and 0.12):** fix #1 (`lsp/tsgo.lua` always returns a
   table, using `root_markers`), #2 (`client:supports_method`), #3 (`vim.diagnostic.jump{count, float=true}`)
   and #4 (`vim.hl.on_yank`).
2. **After upgrading:** #5 (`buffer` → `buf`), optionally #3 → `jump.on_jump` config, #6 diffopt, #7 `gr`.
3. Run `:checkhealth vim.deprecated` on 0.12. It lists every deprecated call that actually ran,
   soft ones included, with tracebacks ([`vim.deprecate` source][deprecate-src] records each call via `vim.deprecated.health`).

## Sources

- Neovim 0.12 release notes, `:h news` @ v0.12.6: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt
- `:h deprecated` @ v0.12.6: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt
- GitHub releases: https://github.com/neovim/neovim/releases/tag/v0.12.0, https://github.com/neovim/neovim/releases/tag/v0.12.6
- neovim PR #37508 (invalid `lsp/*.lua` now errors): https://github.com/neovim/neovim/pull/37508
- Runtime source cited inline (v0.12.6 unless noted).

[news]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L14-L96
[news-defaults]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L139-L154
[news-lsp]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L223-L300
[news-changed]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L463-L494
[depr]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt
[depr-012]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt#L16-L66
[depr-011]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt#L68-L125
[deprecate-src]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/editor.lua#L1259-L1290
[lsp-0115]: https://github.com/neovim/neovim/blob/v0.11.5/runtime/lua/vim/lsp.lua#L421-L428
[lsp-0126-load]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp.lua#L338-L349
[lsp-0126-enable]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp.lua#L614-L634
[pr37508]: https://github.com/neovim/neovim/pull/37508
[fsfind]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/fs.lua#L266-L300
[client-wrap]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp/client.lua#L256-L268
[client-0115]: https://github.com/neovim/neovim/blob/v0.11.5/runtime/lua/vim/lsp/client.lua#L241
[diag-goto]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/diagnostic.lua#L1560-L1567
[diag-float]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/diagnostic.lua#L1235-L1236
[diag-optsjump]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/diagnostic.lua#L330-L332
[defaults-d]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/defaults.lua#L263-L270
[defaults-grx]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/defaults.lua#L212
[hl-shim]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/editor.lua#L1313
[defer-shim]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/shared.lua#L1481-L1498
[keymap-buf]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/keymap.lua#L88-L93
[diffopt]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/options.txt#L2191
[ts-start]: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/treesitter.lua#L450-L462
