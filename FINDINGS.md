# Neovim 0.12 native features vs. each plugin in this config

Ticket: casguz4/kickstart.nvim#6 (map #4). Research only; nothing in the working tree was changed.

- **Baseline:** you're on nvim 0.11.5 now and moving to 0.12 stable. The current stable is **v0.12.6** (2026-10-09). v0.12.0 shipped 2026-03-29 ([release](https://github.com/neovim/neovim/releases/tag/v0.12.0)).
- **Sources:** every Neovim claim below comes from the help files at the `v0.12.6` tag or from runtime source at that tag. At that tag the 0.12 changelog is `runtime/doc/news.txt`; on master it has been renamed to `news-0.12.txt` ([online](https://neovim.io/doc/user/news-0.12.html)). Plugin claims come from each plugin's own repo or docs.
- **Rules from the map (#4):** keep lazy.nvim (no `vim.pack`). Mark a plugin "replaceable" only when the built-in covers how *this* config uses it. Reading the config meant: `init.lua`, `lua/custom/plugins/*`, `lua/kickstart/plugins/*`, `lsp/*`.

Link shorthand: `D` = `https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc`, `R` = `https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim`.

---

## TL;DR

- **Replaceable (4 entries, 3 changes):**
  - **`nvim-ufo` + `promise-async`.** Use `vim.lsp.foldexpr()` with `vim.treesitter.foldexpr()` as the fallback, plus an `indent` fallback.
  - **`copilot.vim`.** Use `vim.lsp.inline_completion` with `copilot-language-server`.
  - **`fidget.nvim`.** Bridge `LspProgress` to `nvim_echo{kind='progress'}`, which shows in the cmdline, and optionally add `vim.ui.progress_status()` to mini.statusline.
- **Replaceable with a caveat:** `LuaSnip`. The swap is blink.cmp's built-in `vim.snippet` preset, which still loads `friendly-snippets`, not core alone. The config only uses LuaSnip as a VSCode-snippet loader, and the repo has no custom Lua snippets.
- **Partial, so keep:** `blink.cmp`, `nvim-treesitter`, `nvim-lspconfig`, `nvim-ts-autotag`, `mini.nvim` (statusline part), `indent-blankline`.
- **Keep, no native equivalent:** everything else. That covers pickers, file tree, bufferline, dashboard, which-key, git signs, formatter/linter runners, DAP, Mason, autopairs, sleuth, todo-comments, theme, CopilotChat, and dependency libraries.
- **New 0.12 features that need config changes but replace no plugin:**
  - Default `gr*` LSP keymaps: your buffer-local `gr` shadows them.
  - `v_an`/`v_in` incremental selection: mini.ai overrides it.
  - `:Undotree`, ui2, `virtual_lines`, the `'diffopt'` defaults (your override drops them), and document colors (on by default).

---

## Verdict table

| Plugin (lazy-lock.json) | How this config uses it | Native overlap in 0.12 | Gaps for *this* config | Verdict hint |
|---|---|---|---|---|
| **blink.cmp** | Auto menu; sources `lsp, path, snippets, lazydev`; `default` keymap preset (`<C-y>` accept, `<C-space>`, `<C-k>` signature); `signature.enabled = true`; Lua fuzzy; LSP capabilities via `get_lsp_capabilities` | `vim.lsp.completion.enable(…, {autotrigger=true})` covers LSP completion. `<C-y>` applies snippets, additional text edits and commands. Results from multiple servers are merged, with a `cmp` sort option (new in 0.12). Resolve preview with `completeopt+=popup` (new in 0.12). `'autocomplete'` + `'complete'` flag `o`/`F` gives completion on every keystroke (new in 0.12). `'completeopt'` has `fuzzy` and `nearest`. `'pumborder'`. `i_CTRL-S` for signature help. | (1) No **path** source in autocomplete: only manual `i_CTRL-X_CTRL-F`. (2) No **snippet-library** source: friendly-snippets would not appear in the menu. (3) No **lazydev** source. (4) Signature help is manual only (`<C-s>`), with no auto-show while typing. (5) Keymap preset and docs-window behavior would need hand-written mappings. | **partial → keep** |
| **LuaSnip** | Only as blink's `snippets.preset = 'luasnip'` and as a loader for friendly-snippets (`luasnip.loaders.from_vscode`). No custom LuaSnip snippets in the repo. | `vim.snippet.expand/jump/active` (since 0.10). `hl-SnippetTabstopActive` is new in 0.12. | Core has no snippet *library or loader*. That gap is filled by blink.cmp's **built-in** `snippets` source: it uses `vim.snippet` by default and auto-loads friendly-snippets. So this replaces LuaSnip with blink defaults, not with core alone. Lost: the jsregexp build and LuaSnip-only features (choice nodes, Lua snippets), none of which are used. | **replaceable (via blink default preset)** |
| **friendly-snippets** | Snippet data | none (it's data) | Still needed as the data source for blink's built-in snippets source | **keep** |
| **nvim-ufo** | Provider chain lsp → treesitter → indent; remaps `zR`/`zM`; adds `foldingRange` capability | `vim.lsp.foldexpr()` and `vim.lsp.foldtext()` (0.11), `vim.lsp.foldclose()`, `vim.treesitter.foldexpr()`, `foldmethod=indent`. The core client already advertises `foldingRange`. `foldtext=''` shows the folded line with its highlighting. `'fillchars'` `foldinner` is new in 0.12. | The chain must be rebuilt by hand. The doc example sets treesitter foldexpr by default and switches to LSP foldexpr on `LspAttach` when the client supports it. Indent needs a `FileType` fallback when there is no parser. Your existing `foldcolumn`/`foldlevel` options carry over. Native `zR`/`zM` work as-is, so the ufo remaps go away. Lost: ufo's async provider and its fold-preview UI, neither of which is configured. | **replaceable** |
| **promise-async** | Dependency of ufo only | n/a | Goes away with ufo | **replaceable (with ufo)** |
| **copilot.vim** | Disabled at startup (`Copilot disable`); `<C-J>` accept; `copilot_no_tab_map`; listed as a CopilotChat dependency | `vim.lsp.inline_completion` (new in 0.12): `enable()/is_enabled()` to toggle, `get()` to accept, `select()` to cycle candidates. `:h lsp-copilot` has a quickstart using `copilot-language-server`. nvim-lspconfig ships `lsp/copilot.lua` with `:LspCopilotSignIn/SignOut`. Mason has a `copilot-language-server` package. | Steps: add the server to `MASON_ENSURED` and `vim.lsp.enable('copilot')`. To keep "off by default", don't call `enable()` at startup and toggle it with a keymap. Map `<C-J>` to `vim.lsp.inline_completion.get()`. Drop the `github/copilot.vim` dependency from CopilotChat: CopilotChat authenticates on its own with GitHub device flow and its README no longer lists copilot.vim. Sign-in moves from `:Copilot setup` to `:LspCopilotSignIn`. | **replaceable** |
| **CopilotChat.nvim** | `<leader>cc` toggle; sticky `#buffer` | none (no native chat) | n/a | **keep** (remove its copilot.vim dependency if copilot.vim goes) |
| **fidget.nvim** | `opts = {}`, so only the LSP progress spinner. It is not overriding `vim.notify`. | Progress messages (`nvim_echo{kind='progress'}`) are new in 0.12, along with the `Progress` autocmd, `vim.ui.progress_status()`, and `'messagesopt'` `progress:c`, which shows them in the cmdline. The default `'statusline'` shows progress and diagnostics. The TUI emits OSC 9;4 progress bars. `vim.lsp.status()` also exists. | **LSP progress is not bridged automatically.** In v0.12.6, `$/progress` only fires `LspProgress`. The `:h LspProgress` doc gives a ~12-line autocmd that re-emits it as a progress message. You use **mini.statusline**, not the default statusline, so progress shows in the cmdline only unless you add `vim.ui.progress_status()` to a mini.statusline section. Lost: fidget's floating corner widget. | **replaceable (small autocmd)** |
| **nvim-treesitter** (main) | Installs 22 parsers (`ts.install`); `vim.treesitter.start` on FileType; `indentexpr` from nvim-treesitter; `jsonc → json` register | Core does highlighting via `vim.treesitter.start` and folding via `vim.treesitter.foldexpr`. Incremental selection (`v_an/v_in/]n/[n/]N/[N`) is new in 0.12. Markdown highlighting is on by default in 0.12. Bundled parsers: C, Lua, Markdown, Vimscript, Vimdoc, Query. | **Parser installation** for the other ~16 languages (ts/tsx/js/css/html/vue/json/yaml/…) and **treesitter `indentexpr`** are not in core. | **partial → keep** |
| **nvim-lspconfig** | Provides `lsp/*.lua` server configs; you already use native `vim.lsp.config/enable` | `vim.lsp.config/enable` (0.11). `:lsp` command and `:checkhealth vim.lsp` are new in 0.12. `vim.lsp.enable()` now stops and detaches clients too. `workspace_required`. | Core ships no per-server config data (cmd/filetypes/root markers) for the 14 servers. You'd have to copy them into `lsp/` yourself. | **keep** (as config data) |
| **nvim-ts-autotag** | `enable_close`, `enable_rename` | `vim.lsp.linked_editing_range` (new in 0.12) mirrors edits between paired tags when the server supports it. vscode-html-language-server and typescript-language-server do; Vue/volar was not verified. | Auto-**close** (`<div>` → `</div>`) is not in LSP linked editing. Rename only works where a server attaches. | **partial → keep** |
| **mini.nvim** (ai, surround, statusline) | mini.ai `n_lines=500`; mini.surround on `gs*`; mini.statusline | 0.12 incremental selection `v_an/v_in`. The default `'statusline'` is now an expression showing diagnostics, LSP progress, `'busy'` and terminal exit code. Native `gc` commenting (0.10) is unrelated to mini here. | **Conflict:** mini.ai's default `around_next/inside_next = 'an'/'in'` override native `v_an/v_in`, and mini.ai's own docs flag this for 0.12 (`MiniAi-default-an-in`). Pick one: remap mini.ai to `aN/iN` or copy the native maps elsewhere. No native surround or textobject equivalent. The default statusline lacks mode, git branch/diff and fileinfo. | **keep** (fix an/in clash) |
| **indent-blankline.nvim** | Guides with `scope` off; excludes `dashboard` | `'listchars'` `leadmultispace` can draw guides on leading spaces. `leadtab` is new in 0.12. | No guides on blank lines. The pattern has to follow per-buffer `shiftwidth`, which vim-sleuth sets. Per-filetype exclude needs autocmds. | **partial → keep** |
| **which-key.nvim** | Key-hint popup, groups | none | n/a | **keep** |
| **fzf-lua** | Files, grep, buffers, help, keymaps, diagnostics, oldfiles, git_bcommits, resume | `:find` + `'findfunc'` (0.11). `'grepprg'` defaults to `rg`. `'wildchar'` completion in `/`, `?`, `:g`. `wildtrigger()` for cmdline autocompletion. Basic `vim.ui.select`. | No fuzzy picker UI, preview, live grep or diagnostics picker | **keep** |
| **neo-tree.nvim** | Right-side tree, `\` reveal, dotfiles shown | netrw (not new) | No tree sidebar or reveal | **keep** |
| **nui.nvim** | Dependency of neo-tree | n/a | n/a | **keep** |
| **bufferline.nvim** | Buffer tabs, pick/close/move, diagnostics, `<leader>1..7` | `'tabline'` shows tabpages, not buffers | n/a | **keep** |
| **dashboard-nvim** | Start screen with fzf-lua actions + lazy stats | `:intro` only | n/a | **keep** |
| **catppuccin** | Colorscheme, transparent | Builtin colorschemes | Make sure the theme covers the new 0.12 groups: `PmenuBorder`, `PmenuShadow*`, `SnippetTabstopActive`, `DiffTextAdd`, `OkMsg`, `StderrMsg`, `StdoutMsg` | **keep** |
| **gitsigns.nvim** | Signs, hunk nav/stage/reset/preview/blame/diffthis | `vim.text.diff` (renamed from `vim.diff`), `:DiffTool` (new in 0.12, `packadd nvim.difftool`), `'diffopt'` `inline:char` | No git-index signs or hunk operations | **keep** |
| **conform.nvim** | prettierd/prettier/stylua, format-on-save, LSP fallback | `vim.lsp.buf.format`, `'formatexpr'` = LSP by default, `vim.lsp.on_type_formatting` (new in 0.12) | No runner for external CLI formatters with `stop_after_first` and format-on-save policy | **keep** |
| **nvim-lint** | eslint_d, stylelint, jsonlint, yamllint, markdownlint | `vim.diagnostic` + `:make`/`'makeprg'` + `vim.diagnostic.fromqflist()` (`merge_lines` is new in 0.12) | No async per-filetype linter runner or parsers | **keep** |
| **nvim-autopairs** | Defaults | none | n/a | **keep** |
| **todo-comments.nvim** | TODO/NOTE highlighting, signs off | none (would mean hand-rolling `matchadd` or treesitter queries) | n/a | **keep** |
| **vim-sleuth** | Indent detection | Built-in EditorConfig (0.9); not heuristic detection | No heuristic detection | **keep** |
| **lazydev.nvim** | blink source + lua_ls library for Neovim API | none | n/a | **keep** |
| **lazy.nvim** | Plugin manager | `vim.pack` (new in 0.12) | The map says keep lazy.nvim | **keep** (map decision) |
| **mason.nvim** | Installs servers/tools; `MasonInstallAll` | none: `vim.pack` handles plugins, not binaries | n/a | **keep** |
| **mason-tool-installer.nvim** | `ensure_installed = MASON_ENSURED` | none | n/a | **keep** |
| **mason-nvim-dap.nvim** | Installs delve, js-debug-adapter, chrome-debug-adapter | none | n/a | **keep** |
| **nvim-dap** | Go + JS/TS debug configs | none (no DAP client in core) | n/a | **keep** |
| **nvim-dap-ui** | Auto open/close UI | none | n/a | **keep** |
| **nvim-dap-go** | delve config | none | n/a | **keep** |
| **nvim-nio** | Dependency of dap-ui | n/a | n/a | **keep** |
| **nvim-web-devicons** | Icons for fzf-lua/bufferline/neo-tree | none | n/a | **keep** |
| **plenary.nvim** | Dependency of neo-tree, todo-comments, CopilotChat | `vim.system`, `vim.uv`, `vim.net.request` (new in 0.12) cover a lot of plenary's surface | The dependent plugins still require it | **keep** |

---

## The specific 0.12 features the ticket asked about

### 1. Completion: `vim.lsp.completion` and `'autocomplete'`
- `vim.lsp.completion.enable(enable, client_id, bufnr, {autotrigger, cmp, convert})`. With `autotrigger=true` it fires on the server's `triggerCharacters`. `<C-y>` accepts and applies snippet expansion, text edits such as auto-imports, and commands. The `cmp` comparator sorts results merged from all servers. [D/lsp.txt#L2128-L2210](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L2128-L2210)
- New in 0.12: `cmp` option, colored symbol preview, resolve preview with `completeopt+=popup`. [D/news.txt#L225-L231](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L225-L231)
- `'autocomplete'` (with `'autocompletedelay'` and `'autocompletetimeout'`) shows the menu as you type, using sources from `'complete'`. New flags: `o` (omnifunc, which is `vim.lsp.omnifunc` in LSP buffers), `F{func}`, and `{flag}^N` limits. [D/options.txt#L768-L795](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/options.txt#L768-L795), [D/insert.txt#L1120-L1155](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/insert.txt#L1120-L1155), [D/news.txt#L325-L333](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L325-L333)
- **Gap vs. this config:** no path, snippet-library or lazydev sources, and no auto signature help (manual `i_CTRL-S` only, [D/lsp.txt#L80-L89](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L80-L89)). Keep blink.

### 2. `vim.snippet` vs. LuaSnip / friendly-snippets
- `vim.snippet.expand/jump/active` exist. 0.12 adds `hl-SnippetTabstopActive`. [D/lua.txt#L4731-L4775](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lua.txt#L4731-L4775), [D/news.txt#L218](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L218)
- blink.cmp: "Blink uses the `vim.snippet` API by default … The built-in `snippets` source will load friendly-snippets, if available." [blink.cmp docs: snippets](https://github.com/saghen/blink.cmp/blob/main/doc/configuration/snippets.md)
- This config only uses LuaSnip to lazy-load the VSCode-format friendly-snippets. Switching `snippets.preset` to `'default'` (and removing the LuaSnip spec) gives the same result on `vim.snippet`.

### 3. LSP/treesitter `foldexpr` vs. nvim-ufo
- `vim.lsp.foldexpr()`, `vim.lsp.foldtext()`, `vim.lsp.foldclose()`. The doc example uses treesitter by default and upgrades to LSP on `LspAttach` when `foldingRange` is supported, which matches ufo's lsp → treesitter chain. [D/lsp.txt#L1155-L1209](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L1155-L1209)
- `vim.treesitter.foldexpr()`. [D/treesitter.txt#L952-L964](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/treesitter.txt#L952-L964)
- `foldtext=''` renders the folded line with its highlighting. [D/options.txt `'foldtext'`](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/options.txt)
- The core client advertises `foldingRange` without help, so the manual capability override goes away with ufo. [R/lsp/protocol.lua](https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp/protocol.lua)
- The indent fallback (ufo's third provider) needs a small `FileType` check: if `vim.treesitter.start` fails, set `foldmethod=indent`.

### 4. Diagnostic `virtual_lines`
- The `virtual_lines` handler (0.11) supports `current_line`, `format` and `severity`, and the docs include a toggle example. [D/diagnostic.txt#L108](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/diagnostic.txt#L108), [#L182-L188](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/diagnostic.txt#L182-L188), [#L710-L722](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/diagnostic.txt#L710-L722)
- No plugin in this config does this (there is no lsp_lines), so it's an optional adoption only.
- 0.12 also adds `vim.diagnostic.status()`, which the default statusline uses. [D/news.txt#L156-L168](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L156-L168)

### 5. Default `gr*` keymaps
- Global defaults: `gra` code_action, `gri` implementation, `grn` rename, `grr` references, `grt` type_definition (new in 0.12), `grx` codelens.run (new in 0.12), `gO` document_symbol, `i_CTRL-S` signature_help, `K` hover. Also `]d`/`[d`/`]D`/`[D`/`<C-w>d` for diagnostics. [D/lsp.txt#L69-L128](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L69-L128), [D/diagnostic.txt#L71-L78](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/diagnostic.txt#L71-L78), [D/news.txt#L150-L152](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L150-L152)
- **This config's `LspAttach` block (`lua/custom/plugins/lspconfig.lua`)** sets a buffer-local `gr` → references. Because the global `grn`/`gra`/`grr`/`gri`/`grt`/`grx` share that prefix, `gr` waits `timeoutlen` (300 ms) before firing ([D/map.txt `:map-nowait`](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/map.txt#L198-L210)).
- It also re-creates defaults that already exist: `K`, `[d`/`]d`.
- Its `[d`/`]d` use `vim.diagnostic.goto_prev/next`, deprecated since 0.11 in favor of `vim.diagnostic.jump()`. [D/deprecated.txt#L80-L81](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt#L80-L81)
- Candidate cleanup: drop `gr`, `K`, `[d`, `]d`, and optionally `<leader>rn`/`<leader>ca`/`gI` in favor of `grn`/`gra`/`gri`.

### 6. ui2 (cmdline/messages)
- `require('vim._core.ui2').enable({...})`. It is **experimental**. It avoids "Press ENTER", highlights the cmdline, and provides a pager buffer and msg/dialog windows. [D/lua.txt#L5569-L5617](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lua.txt#L5569-L5617), [D/news.txt#L426-L432](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L426-L432)
- No current plugin overlaps (no noice.nvim), so it's opt-in polish only.

### 7. LSP progress in the statusline vs. fidget
- New in 0.12: progress messages via `nvim_echo{kind='progress'}`, the `Progress` event, and `vim.ui.progress_status()`. The default `'statusline'` shows progress, and `'messagesopt'` `progress:c` shows it in the cmdline. [D/message.txt#L881-L912](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/message.txt#L881-L912), [D/lua.txt#L5188-L5193](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lua.txt#L5188-L5193), [D/news.txt#L144-L147](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L144-L147), [D/options.txt#L4376-L4394](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/options.txt#L4376-L4394)
- **LSP `$/progress` is not converted to progress messages by default.** The handler only fires `LspProgress` ([R/lsp/handlers.lua#L55-L85](https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/lsp/handlers.lua#L55-L85)). The docs give the bridge autocmd ([D/lsp.txt#L767-L797](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L767-L797)).
- `vim.ui.progress_status()` tracks `Progress` events ([R/ui.lua#L342](https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/ui.lua#L342)).
- The default OSC 9;4 bar comes from the `Progress` autocmd in [R/_core/defaults.lua#L1094-L1105](https://github.com/neovim/neovim/blob/v0.12.6/runtime/lua/vim/_core/defaults.lua#L1094-L1105).
- Since this config uses mini.statusline, add `vim.ui.progress_status()` to a section, or just rely on the cmdline.

### 8. `vim.lsp.inline_completion` vs. copilot.vim
- `enable()`, `is_enabled()`, `get({on_accept})` (returns false when nothing was applied, which allows a fallback), `select({count})`. The `lsp-copilot` quickstart covers `copilot-language-server`. [D/lsp.txt#L2388-L2507](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L2388-L2507)
- nvim-lspconfig `lsp/copilot.lua` provides `:LspCopilotSignIn`/`:LspCopilotSignOut` and an `LspAttach` example. [nvim-lspconfig lsp/copilot.lua](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/copilot.lua)
- Mason package: [mason-registry copilot-language-server](https://github.com/mason-org/mason-registry/blob/main/packages/copilot-language-server/package.yaml)
- CopilotChat does its own GitHub device-flow auth ([providers.lua](https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/lua/CopilotChat/config/providers.lua)), and its README's lazy spec only lists plenary ([README](https://github.com/CopilotC-Nvim/CopilotChat.nvim/blob/main/README.md)). So it doesn't need copilot.vim.

### 9. Built-in commenting
- `gc{motion}`, `gcc`, `v_gc`, `o_gc`, aware of treesitter injections. It has existed since 0.10. [D/various.txt#L601-L643](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/various.txt#L601-L643)
- No comment plugin is installed (todo-comments only highlights). Nothing to replace.

### 10. Treesitter incremental selection
- New in 0.12: `v_an`/`v_in` (parent/child node), `v_]n`/`v_[n`, `v_]N`/`v_[N`. They fall back to LSP `selectionRange` when no parser is attached. Also `vim.treesitter.select()`. [D/treesitter.txt#L610-L640](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/treesitter.txt#L610-L640), [D/news.txt#L249-L250](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L249-L250), [#L409-L412](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L409-L412)
- **This conflicts with mini.ai**, whose default `an`/`in` (next textobject) override the native maps on purpose. Workarounds are in mini.ai's docs. [mini.ai `MiniAi-default-an-in`](https://github.com/echasnovski/mini.nvim/blob/main/doc/mini-ai.txt)

### 11. `:Undotree`
- `:packadd nvim.undotree`, then `:Undotree`. [D/plugins.txt#L273-L283](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/plugins.txt#L273-L283), [D/undo.txt#L131-L137](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/undo.txt#L131-L137)
- No undotree plugin is installed, so this is a free addition (pairs with the existing `undofile = true`).

### 12. Other 0.12 additions relevant here
- **`:DiffTool`** (`packadd nvim.difftool`) compares directories and files. [D/plugins.txt#L48-L60](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/plugins.txt#L48-L60)
- **`'diffopt'` default** is now `internal,filler,closeoff,indent-heuristic,inline:char,linematch:40` ([D/options.txt#L2191](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/options.txt#L2191)). `init.lua` overrides it with `internal,filler,closeoff,hiddenoff,algorithm:patience`, which drops `indent-heuristic`, `inline:char` and `linematch:40`.
- **LSP document colors** are on by default (useful with cssls). [D/lsp.txt#L118-L119](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/lsp.txt#L118-L119)
- **`gx` handles `textDocument/documentLink`.** **`vim.lsp.on_type_formatting`**. **`:lsp`** command for managing clients. [D/news.txt#L232-L272](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L232-L272)
- **`vim.pack`** is the built-in plugin manager. Out of scope per the map. [D/news.txt#L374](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L374)
- **`:restart` / `ZR`.** [D/news.txt#L194-L195](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L194-L195)
- **Deprecations hit by this config.** All are still accepted in 0.12, so cleanup is optional:
  - `vim.highlight.on_yank` → `vim.hl.on_yank`
  - `client.supports_method(...)` → `client:supports_method(...)`
  - `vim.diagnostic.goto_*` → `vim.diagnostic.jump`
  - the `buffer=` key in `vim.keymap.set` opts → `buf=`
  - Sources: [D/deprecated.txt#L16-L66](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt#L16-L66), [#L80-L117](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/deprecated.txt#L80-L117)
- **Breaking:** `'shelltemp'` now defaults to false. `i_CTRL-R` inserts literally. [D/news.txt#L36-L77](https://github.com/neovim/neovim/blob/v0.12.6/runtime/doc/news.txt#L36-L77)

---

## Asides found while reading the config (not 0.12-specific, but they'll surface during the upgrade)
- **`lua/custom/plugins/dap-js.lua` calls `mason-registry…:get_install_path()`.** That method was removed in mason.nvim 2.0 ([mason CHANGELOG](https://github.com/mason-org/mason.nvim/blob/main/CHANGELOG.md)), and the lockfile pins mason 2.2.1 (commit `44d1e90`). This code path is likely already broken.
- **`vim.lsp.enable{'volar'}`:** nvim-lspconfig's `lsp/volar.lua` now says "Renamed to vue_ls". [lsp/volar.lua](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/volar.lua)
- **nvim-dap and nvim-lint are each specified twice** (kickstart and custom). lazy.nvim merges the specs, so the later `config` wins.
- **bufferline `offsets` targets `NvimTree`,** but the tree in use is neo-tree (`neo-tree` filetype).

## Method
- Read `lazy-lock.json` (37 plugins) and every plugin spec under `init.lua`, `lua/custom/plugins/`, `lua/kickstart/plugins/` and `lsp/`.
- Downloaded the `v0.12.6` help files and the relevant runtime Lua (`lsp/handlers.lua`, `ui.lua`, `_core/defaults.lua`, `lsp/protocol.lua`) and checked each claim against them.
- Plugin-side claims were checked against each project's current docs: blink.cmp snippets doc, mini.ai help, CopilotChat README and providers.lua, nvim-lspconfig `lsp/*.lua`, the mason CHANGELOG, the mason-registry package, and typescript-language-server's CHANGELOG for `linkedEditingRange`.
- Not verified: whether vue_ls/volar supports `linkedEditingRange`.
