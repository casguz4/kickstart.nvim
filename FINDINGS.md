# Plugin compatibility on Neovim 0.12 + Mason 2

Research for casguz4/kickstart.nvim#9 (map #4). Researched 2026-11-01 against GitHub (via `gh api`) and the user's installed plugin checkouts (`~/.local/share/nvim/lazy/*`, which match `lazy-lock.json`).

Target: Neovim **0.12 stable**, currently **v0.12.6** (2026-10-09; 0.12.0 shipped 2026-03-29). https://github.com/neovim/neovim/releases/tag/v0.12.6

## TL;DR

- **No plugin in `lazy-lock.json` is archived** (GitHub `archived` = false for all 37). One is formally deprecated: **plenary.nvim**. Its README says it is no longer maintained and will be archived, with critical fixes only until 2026-06-30. You only get it as a dependency (neo-tree, todo-comments, CopilotChat).
- **Nothing hard-breaks at startup on 0.12 at the current pins.** Some pins have 0.12-specific runtime bugs that are fixed upstream: **blink.cmp** (`vim.NIL` in LSP items), **fidget** (`vim.NIL` in progress), **nvim-ts-autotag** (nil parser in rename), **nvim-nio** (deprecation popups), and **fzf-lua**. **Upgrade Neovim, then `:Lazy update`, then `:TSUpdate`.**
- **Ordering matters for nvim-treesitter `main`.** The pin (2026-02-21) supports 0.11 and 0.12. Latest `main` **drops 0.11** (commit `c82bf96`, 2026-04-01). Don't update it while still on 0.11.5. The `main` API this config uses (`install`, `get_installed`, `indentexpr`) is unchanged.
- **Catppuccin trap:** Neovim 0.12 ships a built-in `colors/catppuccin.vim`, and `:colorscheme` tries `.vim` files first. So after updating catppuccin, `vim.cmd.colorscheme 'catppuccin'` loads Neovim's built-in Vim port instead of the plugin, and your `opts` are ignored. Use **`catppuccin-nvim`**.
- **Mason 2:** `Package:get_install_path()` was removed in mason.nvim 2.0.0, and the pin is already v2.2.1. Replace it with `command = 'js-debug-adapter'` (the Mason bin shim) or `vim.fn.expand('$MASON/packages/js-debug-adapter/js-debug/src/dapDebugServer.js')`. **But `dap-js.lua` never runs today.** lazy.nvim keeps only the last `config` for `nvim-dap`, and that is `custom/plugins/debug.lua`. So JS debugging through js-debug is silently missing right now.
- **mason-tool-installer and mason-nvim-dap both work on Mason 2.** But **`chrome-debug-adapter` was removed from the Mason registry on 2026-04-07**. mason-tool-installer calls `get_package` without a guard, so it errors on a fresh machine. It works here only because the package is installed locally, which makes Mason "synthesize" it.
- **`volar` -> `vue_ls`.** `volar` is a deprecated alias in nvim-lspconfig. vue_ls v3 also needs `ts_ls`/`vtsls` with `@vue/typescript-plugin` attached to `vue` buffers, which this config doesn't set up.
- **lazy.nvim works on 0.12** but is dormant: no `main` commits since 2025-12-17, and folke is working on other projects. Upstream kickstart has moved to `vim.pack`. Decision stands: keep lazy.

## Plugin table

Pin date = committer date of the locked commit. "= latest" means the pin is the branch HEAD.

| plugin | pin date | 0.12 status | breaking issues | maintained? | action |
|---|---|---|---|---|---|
| CopilotChat.nvim | 2026-02-12 | OK (needs nvim 0.10+) | Config: sticky `` #buffer:`current` `` is not a valid scope (valid: `active`, `visible`, `listed`, `quickfix`). `copilot.vim` is no longer a required dependency. | Active (2026-10-23) | Update. Change sticky to `#buffer:active`. Drop the copilot.vim dependency. |
| LuaSnip | 2025-11-03 (v2.4.1) | OK | `extras/snippet_list` calls the removed `vim.diagnostic.disable` (you don't use it) | Active (v2.5.0, 0.12 CI) | Update (stays on `2.*`) |
| blink.cmp | 2026-02-04 (v1.9.1) | **Bug at pin:** 0.12 sends JSON null as `vim.NIL`, which breaks completion with some servers (#2456, #2466) | Fixed in **v1.10.2**. `main` is now V2: breaking, needs `blink.lib`. | Very active | Update inside `version = '1.*'` (-> v1.10.2). Do **not** track `main`. |
| bufferline.nvim | 2025-01-14 (v4.9.1) = latest | OK (deprecated calls are guarded) | None known | **Dormant:** no commits since 2025-01-14 (not archived) | Keep. Optionally switch to `mini.tabline` later. |
| catppuccin | 2026-02-15 | OK at pin | **At latest:** colorscheme renamed `catppuccin` -> `catppuccin-nvim` (#977) to avoid clashing with Nvim 0.12's built-in `catppuccin.vim`. v2.0.0 also removed `default_integrations` and `show_end_of_buffer`. | Active | When updating, use `vim.cmd.colorscheme 'catppuccin-nvim'` |
| conform.nvim | 2026-01-18 | OK | `vim.diff` is soft-deprecated (renamed `vim.text.diff`). Fixed upstream 2026-05-14. | Active | Update |
| copilot.vim | 2026-01-09 (1.59.0) = latest | Works. Requests use `client:request` with a guard, but the unguarded `client.notify` shows a one-time deprecation message. | None | **Stalled:** no release since 2026-01-09 (not archived) | Keep for now. Separate ticket: Nvim 0.12 has `vim.lsp.inline_completion`, Mason has `copilot-language-server`, and lspconfig has a `copilot` config. |
| dashboard-nvim | 2025-08-31 | OK | None known | Low activity (last commit 2026-04-17) | Update |
| fidget.nvim | 2026-01-13 | **Bug at pin:** `vim.NIL` in LSP progress fields (fixed 2026-05-21, #310) | v2.0.0: nvim-tree/xcodebuild integrations removed, window reflow defaults changed (no config impact) | Active | Update |
| friendly-snippets | 2026-01-23 | OK | - | Active | Update |
| fzf-lua | 2026-02-21 | Mostly OK. Several 0.12 fixes landed after the pin (e.g. #2616, first character lost after `grep_lgrep` toggle). | - | Very active | Update |
| gitsigns.nvim | 2026-02-13 | OK | Latest changed `:Gitsigns show`/`show_commit` (fd78092). The config's keymaps don't use them; every function it calls still exists. | Active | Update |
| indent-blankline.nvim | 2026-02-17 | OK | - | Active (v3.10.1) | Update |
| lazy.nvim | 2025-12-17 = latest | **Works.** The only reported 0.12 bug (#2146, `:restart`) was an upstream Nvim bug, closed 2026-04-03. Open: #2153, parsers installed into `site/` are not on rtp during the very first bootstrap session. | - | **Dormant:** no `main` commits for over 10 months; stalebot complaints; folke busy elsewhere | Keep (map decision). Nothing to update. |
| lazydev.nvim | 2025-11-06 | OK | Open #145 (listener leak on lua_ls restart) | Low activity (2026-03) | Update |
| mason-nvim-dap.nvim | 2025-10-20 = latest | OK on Mason 2 (uses `registry.refresh`, no `get_install_path`) | Config: `ensure_installed` expects **nvim-dap adapter names** (`delve`, `js`, `chrome`). `'js-debug-adapter'` and `'chrome-debug-adapter'` are silently ignored. It has no js-debug (`pwa-node`) auto-setup at all. | Dormant | Keep. Fix names, or drop them (mason-tool-installer already installs them). |
| mason-tool-installer.nvim | 2026-01-22 = latest | OK on Mason 2 (branches on `mason.version.MAJOR_VERSION`) | `mr.get_package(name)` is unguarded, so it errors for any name missing from the registry. **`chrome-debug-adapter` is gone from the registry.** | Low activity | Remove `chrome-debug-adapter` from `MASON_ENSURED` |
| mason.nvim | 2026-01-07 (v2.2.1) | OK (min nvim 0.10; CI covers 0.12.2/0.12.3) | `Package:get_install_path()` removed in 2.0.0 (used in `dap-js.lua`) | Active (v2.3.1, 2026-06-11) | Update. Fix `dap-js.lua` (see below). Use the `mason-org/` URL everywhere. |
| mini.nvim | 2026-02-21 | OK (0.12 is current stable in CI) | Repo moved `echasnovski/mini.nvim` -> **`nvim-mini/mini.nvim`** (GitHub redirects) | Very active (v0.18.0) | Change the spec URL to `nvim-mini/mini.nvim` |
| neo-tree.nvim | 2025-11-04 (3.38.0) | OK (0.12 in CI since 3.41.0) | - | Active (3.42.0) | Update (`version = '*'`) |
| nui.nvim | 2025-06-08 | OK | - | Low activity but alive (2026-08) | Update |
| nvim-autopairs | 2026-01-30 | OK | - | Active | Update |
| nvim-dap | 2026-02-11 | OK | - | Active | Update |
| nvim-dap-go | 2025-07-11 = latest | OK. `get_root_dir` uses the deprecated `vim.lsp.buf_get_clients` (still present in 0.12, shows a warning). | - | Dormant | Keep |
| nvim-dap-ui | 2025-07-09 | OK | Latest adds `vim.tbl_flatten` / `vim.validate{}` deprecation warnings on 0.12 (#487, open) | Low activity | Optional update |
| nvim-lint | 2026-02-18 | OK | - | Active | Update |
| nvim-lspconfig | 2026-02-21 | OK (requires nvim 0.11.3+) | `volar` is a deprecated alias of `vue_ls` (calls `vim.deprecate`). Upstream also renamed `stylelint` and `ruff_lsp` (not used here). | Very active (v2.12.0) | Update. Rename `volar` -> `vue_ls`. Fix the Vue/TS hybrid setup. |
| nvim-nio | 2025-01-20 | Works, but `client.request` deprecation popup on 0.12 (#33) | Fixed 2026-07-15 | Low activity | Update |
| nvim-treesitter (`main`) | 2026-02-21 | OK (pin supports 0.11+) | **Latest requires Nvim 0.12** (`feat!: drop support for Nvim 0.11`, c82bf96, 2026-04-01). Needs tree-sitter CLI >= 0.26.1 (Mason's `tree-sitter-cli` is the GitHub binary, 0.26.5 installed, so OK). No `jsonc` parser, so `register('json','jsonc')` is correct. | Very active | **Upgrade Nvim first**, then update and run `:TSUpdate` |
| nvim-ts-autotag | 2026-02-04 | **Bug at pin:** nil parser in `rename_tag` on 0.12, because `get_parser()` now returns nil instead of throwing (fixed #260, 2026-04-15) | - | Active | Update. Optionally drop the unneeded `nvim-treesitter` dependency. |
| nvim-ufo | 2026-01-11 = latest | OK (`getParser` handles nil) | - | Low activity; author still replies (2026-10-23) | Keep. Optional: native `vim.lsp.foldexpr()` + treesitter folds. |
| nvim-web-devicons | 2026-02-04 | OK | - | Active | Update |
| plenary.nvim | 2025-07-26 | OK | - | **Deprecated:** README says unmaintained, critical fixes only until 2026-06-30, will be archived | Keep as a transitive dependency. Watch neo-tree #2014. |
| promise-async | 2024-08-04 = latest | OK | - | Dormant (stable) | Keep (ufo dependency) |
| todo-comments.nvim | 2025-11-10 = latest | OK | - | Dormant | Keep |
| vim-sleuth | 2024-09-19 = latest | OK | - | Stable/dormant | Keep |
| which-key.nvim | 2025-10-28 = latest | OK | - | Dormant | Keep |

### Core 0.12 changes that matter here

From `news.txt` / `deprecated.txt` at v0.12.6:

- **Breaking:** JSON `null` in LSP messages is now `vim.NIL`. This is the root of the blink and fidget bugs.
- **Breaking:** `vim.treesitter.get_parser()` returns nil instead of throwing. This is the root of the nvim-ts-autotag bug.
- **Breaking:** the `all` option of `Query:iter_matches()` was removed. Passing it is harmless.
- **Breaking:** `vim.diagnostic.disable()`/`is_disabled()` were removed. All callers in the pinned plugins are guarded, except the unused LuaSnip extra.
- **Breaking:** diagnostic signs can no longer be set via `sign_define`.
- **Hard-deprecated, removed in 0.13:** dot-call `client.supports_method()`/`request()`/`notify()`, `vim.diagnostic.goto_next/prev()`, `vim.tbl_flatten()`. In 0.12 these show a one-time "X is deprecated" message, so expect a few after upgrading. Run `:checkhealth vim.deprecated` to list them.
- **New:** `vim.pack`, `vim.lsp.inline_completion`, `:lsp`, `:Undotree`, `:DiffTool`, default `grt`/`grx` maps, and `'diffopt'` now defaults to include `indent-heuristic,inline:char`.
- **Built-in colorscheme `catppuccin.vim`** (vim-patch b424349, neovim commit d436059).

## Mason 2: what replaces `get_install_path()`

From the mason.nvim 2.0.0 changelog:

1. To run an executable, use its bin name on `PATH` (Mason prepends `$MASON/bin`), or `vim.fn.exepath(...)`.
2. To reach files inside a package, prefer `$MASON/share/...`.
3. If you really need the package directory: `vim.fn.expand("$MASON/packages/<pkg>/...")`. Only `bin/`, `share/` and `opt/` are stable interfaces.

The js-debug-adapter registry entry defines `bin: js-debug-adapter: node:js-debug/src/dapDebugServer.js`. On this machine `$MASON/bin/js-debug-adapter` is a shim that runs `node .../packages/js-debug-adapter/js-debug/src/dapDebugServer.js "$@"`. I checked this headless on mason v2.2.1: `get_install_path` is `nil`, and the `$MASON/packages/...` path exists.

Replacement for both adapters in `dap-js.lua`:

```lua
executable = { command = 'js-debug-adapter', args = { '${port}' } }
-- or, explicit path:
-- executable = { command = 'node', args = { vim.fn.expand('$MASON/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'), '${port}' } }
```

## Config-level misuses spotted

1. **Three `mfussenegger/nvim-dap` specs, and only one `config` runs.** The specs are `kickstart/plugins/debug.lua`, `custom/plugins/dap-js.lua` and `custom/plugins/debug.lua`. lazy.nvim merges `opts/dependencies/cmd/event/ft/keys` across specs; every other key, including `config`, is overridden by the later spec. `import = 'custom.plugins'` loads modules in sorted order. I confirmed it headless: the resolved `config` comes from `custom/plugins/debug.lua:80`, with 3 fragments. So `dap-js.lua`'s `pwa-node`/`pwa-chrome` adapters are **never registered**, and the `get_install_path()` crash is latent. **Fix:** merge everything into one dap spec and use the Mason-2 path above.
2. **nvim-lint is configured twice** (`kickstart/plugins/lint.lua` and `custom/plugins/lint.lua`). The custom one wins (confirmed), so the kickstart one is dead code. Drop `require 'kickstart.plugins.lint'`.
3. **mason.nvim is referenced under two URLs.** Both debug files use `williamboman/mason.nvim`; `lspconfig.lua` uses `mason-org/mason.nvim`. lazy merges them by name and the last URL wins (resolved: mason-org). Use `mason-org/` everywhere.
4. **`<leader>b` is bound twice:** FzfLua buffers (init.lua) and DAP toggle breakpoint (both debug files).
5. **`chrome-debug-adapter`** was deprecated 2025-08-01 ("superseded by js-debug-adapter") and removed from mason-registry 2026-04-07. Remove it from `MASON_ENSURED` and from mason-nvim-dap `ensure_installed`. The names there should be `js`/`delve`, not package names.
6. **Vue:** `vim.lsp.enable 'volar'` should be `'vue_ls'`. vue_ls v3 has no takeover mode. It forwards TS requests to `ts_ls`/`vtsls`, which must have `@vue/typescript-plugin` in `init_options.plugins` and `vue` in `filetypes`. The current `ts_ls` override has neither, so `vue_ls` will report "Could not find `ts_ls`, `vtsls`, or `typescript-tools`".
7. **`tsgo`** (used when `$TSGOPATH` is set; installed via Mason): the Mason package is deprecated as of 2026-08-13 ("released as TypeScript 7... use the package `tsc`"). The registry removes deprecated packages after about 3 months.
8. **Deprecated core calls in your own config** (they warn in 0.12 and break in 0.13):
   - `client.supports_method 'textDocument/inlayHint'` -> `client:supports_method('textDocument/inlayHint', bufnr)`
   - `vim.diagnostic.goto_prev/next` -> `vim.diagnostic.jump({ count = -1/1, float = true })`, or just delete them: `[d`/`]d` are defaults since 0.11.
   - `vim.keymap.set(..., { buffer = ... })` -> `buf` (soft-deprecated in 0.12)
9. **Colorscheme:** change `vim.cmd.colorscheme 'catppuccin'` to `'catppuccin-nvim'` when catppuccin is updated (see table).
10. **CopilotChat:** the sticky `` #buffer:`current` `` should be `#buffer:active`. Remove `github/copilot.vim` from its dependencies; it isn't required anymore.
11. Minor and optional:
    - The `vim.opt.diffopt` override drops the new 0.12 defaults (`indent-heuristic`, `inline:char`, `linematch`).
    - The buffer-local `gr` -> references map shadows the built-in `grn/gra/grr/gri/grt/grx` maps, which adds a `timeoutlen` wait.

## Suggested upgrade order

1. Stay on the current lockfile while still on 0.11.5. In particular, **don't** update nvim-treesitter past `c82bf96`.
2. Install Nvim 0.12.6.
3. Apply the config fixes above: colorscheme name, one dap spec, js-debug path, drop chrome-debug-adapter, `vue_ls`, mini URL, `mason-org` URL.
4. Run `:Lazy update`, then `:TSUpdate`, then `:checkhealth vim.deprecated` and `:checkhealth nvim-treesitter`.
5. Commit the new `lazy-lock.json`.

## Sources

- Neovim releases: https://github.com/neovim/neovim/releases (v0.12.0 2026-03-29, v0.12.6 2026-10-09)
- Neovim 0.12 news: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt
- Neovim deprecations: https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt
- `vim.deprecate` behaviour: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/editor.lua
- Client dot-call shim: https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp/client.lua
- Built-in catppuccin colorscheme: https://github.com/neovim/neovim/commit/d4360596b5ce0d98ab8d81d1fee3e4950cbc4189
- `:colorscheme` lookup order (".vim tried first"): https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/syntax.txt
- catppuccin rename PR: https://github.com/catppuccin/nvim/pull/977 and README https://github.com/catppuccin/nvim#usage
- mason.nvim CHANGELOG (2.0.0 `get_install_path` removal and replacements): https://github.com/mason-org/mason.nvim/blob/main/CHANGELOG.md
- Mason removed-package synthesis: https://github.com/mason-org/mason.nvim/pull/2052
- Mason `get_package` errors on unknown names: https://github.com/mason-org/mason.nvim/blob/v2.3.1/lua/mason-registry/init.lua
- js-debug-adapter package: https://github.com/mason-org/mason-registry/blob/main/packages/js-debug-adapter/package.yaml
- chrome-debug-adapter deprecation: https://github.com/mason-org/mason-registry/commit/92d02ef189 and removal: https://github.com/mason-org/mason-registry/commit/784c119569
- tsgo deprecation: https://github.com/mason-org/mason-registry/blob/main/packages/tsgo/package.yaml
- vue-language-server -> `vue_ls`: https://github.com/mason-org/mason-registry/blob/main/packages/vue-language-server/package.yaml
- mason-tool-installer Mason 1/2 branching: https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/blob/main/lua/mason-tool-installer/init.lua and issue https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/issues/86
- mason-nvim-dap source mappings / settings: https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua, https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/ensure_installed.lua
- nvim-treesitter main README (requires 0.12, tree-sitter-cli >= 0.26.1): https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md
- nvim-treesitter drop 0.11: https://github.com/nvim-treesitter/nvim-treesitter/commit/c82bf96f0a
- nvim-treesitter health at pin (0.11 minimum): https://github.com/nvim-treesitter/nvim-treesitter/blob/dc42c209f3820bdfaae0956f15de29689aa6b451/lua/nvim-treesitter/health.lua
- nvim-lspconfig `volar` alias: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/volar.lua, `vue_ls`: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vue_ls.lua, `ts_ls`: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/ts_ls.lua, `copilot`: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/copilot.lua
- lazy.nvim spec merging rules: https://github.com/folke/lazy.nvim/blob/main/doc/lazy.nvim.txt (Importing Specs: `opts`, `dependencies`, `cmd`, `event`, `ft`, `keys` merge; others override); import sort: https://github.com/folke/lazy.nvim/blob/main/lua/lazy/core/plugin.lua
- lazy.nvim 0.12 issues: https://github.com/folke/lazy.nvim/issues/2146, https://github.com/neovim/neovim/issues/38733, https://github.com/folke/lazy.nvim/issues/2153
- blink.cmp `vim.NIL` fixes / V2 notice: https://github.com/saghen/blink.cmp/releases/tag/v1.10.2, https://github.com/saghen/blink.cmp/issues/2456, https://github.com/saghen/blink.cmp#readme
- fidget `vim.NIL` fix: https://github.com/j-hui/fidget.nvim/pull/310
- nvim-ts-autotag nil-parser fix: https://github.com/windwp/nvim-ts-autotag/pull/260
- nvim-nio deprecation fix: https://github.com/nvim-neotest/nvim-nio/issues/33
- nvim-dap-ui 0.12 warnings: https://github.com/rcarriga/nvim-dap-ui/issues/487
- fzf-lua 0.12 issues: https://github.com/ibhagwan/fzf-lua/issues/2616, https://github.com/ibhagwan/fzf-lua/issues/2638
- plenary deprecation: https://github.com/nvim-lua/plenary.nvim#important-notice, https://github.com/nvim-neo-tree/neo-tree.nvim/issues/2014
- mini.nvim move: https://github.com/nvim-mini/mini.nvim
- CopilotChat requirements / resources: https://github.com/CopilotC-Nvim/CopilotChat.nvim#readme, https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/lua/CopilotChat/config/functions.lua
- copilot.vim releases: https://github.com/github/copilot.vim/commits/release
- gitsigns show/diff change: https://github.com/lewis6991/gitsigns.nvim/commit/fd7809206
- kickstart upstream (now `vim.pack`, `nvim-mini/mini.nvim`): https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua
- Archived status / dates: GitHub REST `repos/{owner}/{repo}` and `repos/{owner}/{repo}/commits/{sha}` for each lockfile entry (queried 2026-11-01).
