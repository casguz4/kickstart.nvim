# TypeScript 7 (tsgo) as the JS/TS language server: state as of 2026-11-01

Ticket: casguz4/kickstart.nvim#7 (map #4). I checked every claim against a primary source on 2026-11-01: the npm registry, the TypeScript source, the nvim-lspconfig, mason-registry and Homebrew sources, the Vue language-tools issues and PRs, and the TypeScript dev blog.

## TL;DR

- **TypeScript 7.0 is GA.** It was released on 2026-07-08 and the current version is `typescript@7.0.2`. TS 7.1 is in beta (`7.1.0-beta`, 2026-10-20), with the RC expected about a month later and the final release soon after that.
- **The name "tsgo" is retired.** Install it as **`typescript@7`** (the binary is `tsc`, and the server runs with `tsc --lsp --stdio`). `@typescript/native-preview` stopped updating on 2026-07-07.
- **Mason:** use the package **`tsc`** (pinned to `typescript@7.0.2`). The Mason package `tsgo` is deprecated. **Homebrew:** `typescript` 7.0.2.
- **nvim-lspconfig:** the config is now named **`tsc`**, and `tsgo` is a deprecated alias for it.
- **LSP features:** close to parity with ts_ls for daily use. Inlay hints, rename, quick fixes, organize/sort/remove-unused imports, fix-all, auto-imports, workspace symbols, call hierarchy, formatting, code lens and semantic tokens all work. **Refactorings** (extract, move to file, and so on) appear to be missing, and so are type hierarchy and `workspace/executeCommand`.
- **Vue does not work with TS 7.0.** Volar's hybrid mode needs tsserver plus `@vue/typescript-plugin`, and TS 7 has no tsserver and no plugin model. Both the TypeScript team and the Vue team say to stay on TS 6 (ts_ls or vtsls) for Vue editing for now. Real support is coming in Vue Language Tools **v4**, which only works with **TS 7.1** through "content mappers". v4 is still a draft PR, and Neovim will need client glue that nvim-lspconfig does not have yet.

**What this means for the config:** use `tsc` (Mason `tsc`) for JS/TS/JSX/TSX. Any `.vue` work still needs `vtsls` (or `ts_ls`) with `@vue/typescript-plugin` attached to `vue` buffers only, plus `vue_ls`. That lasts until Vue LS v4 ships on top of TS 7.1. If "tsgo is the sole JS/TS server" is a hard rule, Vue editing loses all TypeScript intelligence in the meantime.

---

## 1. Release status

| Item | State | Source |
|---|---|---|
| TS 7.0 final | Released 2026-07-08 ("Announcing TypeScript 7.0") | https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/ |
| npm `typescript` dist-tags (2026-11-01) | `latest: 7.0.2`, `beta: 7.1.0-beta`, `rc: 7.0.1-rc`, `next: 7.1.0-dev.20261031.1` (nightlies now ship on `typescript@next`) | https://registry.npmjs.org/typescript |
| TS 7.1 | Beta on 2026-10-20. "Release Candidate in about a month from now, followed by a final release shortly thereafter." Adds the new programmatic API and **content mappers** | https://devblogs.microsoft.com/typescript/announcing-typescript-7-1-beta/ |
| `@typescript/native-preview` | Last publish `7.0.0-dev.20260707.2` (2026-07-07). Superseded, no longer updated | https://registry.npmjs.org/@typescript/native-preview |
| `microsoft/typescript-go` repo | Archived: "This Repo Is Closed ... continue development ... in microsoft/TypeScript". The Go code now lives in `microsoft/TypeScript` under `tsc/` | https://github.com/microsoft/typescript-go |
| Side-by-side TS 6 | `@typescript/typescript6` provides a `tsc6` binary for tools that still need the JS API | TS 7.0 announcement (above) |

The 7.0 post says the native LSP "reduced failing language server commands by over 80%, and reduced server crashes by over 60% compared to that of TypeScript 6.0."

## 2. Install route

- **npm (canonical):** `npm install -D typescript` installs the new `tsc`, run as `npx tsc` (TS 7.0 post). There is no separate `tsgo` binary anymore. The old README says "For TypeScript 7.0 RC and later, the command name is `tsc`" (https://github.com/microsoft/typescript-go#preview).
- **LSP entry point:** `tsc --lsp --stdio`. `--lsp` must be the **first** argument, because `runMain` switches on `args[0] == "--lsp"`. `--stdio`, `--pipe`, `--socket` and `--clientProcessId` are flags of the lsp subcommand. Source: https://github.com/microsoft/TypeScript/blob/main/tsc/cmd/tsc/main.go and https://github.com/microsoft/TypeScript/blob/main/tsc/cmd/tsc/lsp.go. Note that the old local `lsp/tsgo.lua` uses `tsgo lsp --stdio`, which is the pre-release subcommand form.
- **Mason:** package **`tsc`**. Its source is `pkg:npm/typescript@7.0.2`, it exposes the `tsc` binary, and it maps to `neovim.lspconfig: tsc` (https://github.com/mason-org/mason-registry/blob/main/packages/tsc/package.yaml). The Mason **`tsgo`** package is deprecated since 2026-08-13 ("...released as TypeScript 7 in the regular typescript package. Use the package `tsc` instead.") and is stuck on `@typescript/native-preview@7.0.0-dev.20260707.2` (https://github.com/mason-org/mason-registry/blob/main/packages/tsgo/package.yaml). mason-lspconfig builds its name map from the registry's `neovim.lspconfig` field, so `ensure_installed = { 'tsc' }` resolves to the `tsc` server (https://github.com/mason-org/mason-lspconfig.nvim/blob/main/lua/mason-lspconfig/mappings.lua). *The local machine still has the deprecated Mason `tsgo` package installed.*
- **Homebrew:** formula `typescript` is at 7.0.2 and built from `microsoft/TypeScript` tag v7.0.2 (https://formulae.brew.sh/api/formula/typescript.json). There is no `tsgo` formula.
- **Mason side effects of TS 7 becoming `latest`:** Mason now pins `typescript@6.0.3` inside `typescript-language-server` (ts_ls needs `lib/tsserver.js`, which TS 7 removed; mason-registry#15985) and inside `vue-language-server` (vue_ls crashed on TS 7; mason-registry#15934). See https://github.com/mason-org/mason-registry/issues/15985, https://github.com/mason-org/mason-registry/issues/15934, https://github.com/mason-org/mason-registry/blob/main/packages/vue-language-server/package.yaml and https://github.com/mason-org/mason-registry/blob/main/packages/typescript-language-server/package.yaml.

## 3. nvim-lspconfig config

Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/tsc.lua (added in #4493 on 2026-08-12, with CodeLens added in #4501 and the `--lsp` check in #4505).

- **Name:** `tsc`. `lsp/tsgo.lua` is now a deprecated alias that wraps `vim.lsp.config.tsc` and fires `vim.deprecate('tsgo', 'tsc', '3.0.0', ...)` (https://github.com/neovim/nvim-lspconfig/blob/master/lsp/tsgo.lua).
- **cmd:** a function that starts `{ <bin>, '--lsp', '--stdio' }`. It picks `<bin>` per root, in this order: `<root>/node_modules/.bin/tsc`, `tsc` on PATH, `<root>/node_modules/.bin/tsgo`, `tsgo` on PATH. It only accepts a binary whose `--version` major is 7 or higher, which skips a project-local TS 6 in favour of the Mason/global TS 7. If nothing qualifies, it warns: "no binary supporting `--lsp` found (requires TypeScript 7.0+)".
- **filetypes:** `javascript`, `javascriptreact`, `typescript`, `typescriptreact`. **No `vue`.**
- **root:** a `root_dir` function, not plain `root_markers`. The markers are `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb` and `bun.lock` (equal priority), then `.git`, and it falls back to the cwd. It bails out when a `deno.json`, `deno.jsonc` or `deno.lock` is closer than the lockfile. It is monorepo-aware: one instance serves the whole workspace.
- **Default settings** (sent under `settings['js/ts']`): every inlay hint category is on (`parameterNames.enabled = 'literals'` with `suppressWhenArgumentMatchesName = true`, plus `parameterTypes`, `variableTypes`, `propertyDeclarationTypes`, `functionLikeReturnTypes` and `enumMemberValues`), and references/implementations CodeLens are on.

The `vue_ls` config still only forwards `tsserver/request` to a client named `ts_ls`, `vtsls` or `typescript-tools`. It never looks for `tsc` (https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vue_ls.lua). `lsp/volar.lua` is a "Renamed to vue_ls" stub, and the current config still enables `'volar'`.

## 4. LSP features vs ts_ls / tsserver

Server capabilities come from https://github.com/microsoft/TypeScript/blob/main/tsc/internal/lsp/server.go (main branch, 2026-10-31).

| Feature | tsc 7 LSP | Notes |
|---|---|---|
| Diagnostics (push + pull) | yes | `DiagnosticProvider`. Push can be turned off with `initializationOptions.disablePushDiagnostics` |
| Hover, completion (+resolve), signature help | yes | |
| Definition / type definition / implementation / references | yes | Also has custom source-definition and multi-document highlight |
| **Rename** (+ prepareRename) | yes | `RenameProvider` with `PrepareProvider`. `workspace/willRenameFiles` updates imports |
| **Code actions** | partial | Advertised kinds: `quickfix`, `source.organizeImports.ts`, `source.removeUnusedImports.ts`, `source.sortImports.ts`, `source.fixAll.ts` (`supportedCodeActionKinds()` in server.go and `lsproto/lsp.go`). **No `refactor.*` kinds**, so extract function/constant, move to file and similar refactorings appear to be missing. "Port `move to file` refactoring" is still open (https://github.com/microsoft/TypeScript/issues/63788) and the "no refactorings available" report was closed as its duplicate (https://github.com/microsoft/typescript-go/issues/3580) |
| **Organize imports** | yes | It is a code action, not a command: `vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })`. The server expands the requested kind through `getOrganizeImportsActionsForKind` (`tsc/internal/ls/codeactions.go`). There is no `workspace/executeCommand` handler, so ts_ls-style `_typescript.organizeImports` commands do not exist |
| **Auto-imports** | yes | Completions plus import quick fixes. Settings: `preferences.importModuleSpecifier`, `preferences.importModuleSpecifierEnding`, `preferences.preferTypeOnlyAutoImports`, `preferences.autoImportFileExcludePatterns`, `preferences.autoImportSpecifierExcludeRegexes`, `suggest.autoImports` |
| **Workspace symbols** | yes | `WorkspaceSymbolProvider`. `workspaceSymbols.scope` is `allOpenProjects` or `currentProject`, and `workspaceSymbols.excludeLibrarySymbols` |
| **Call hierarchy** | yes | `CallHierarchyProvider` |
| Type hierarchy | **no** | Not advertised |
| **Formatting** (document / range / on-type) | yes | All three providers. Settings: `format.*` (for example `format.semicolons`, `format.insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces`), and it reads `editor.tabSize` / `editor.insertSpaces` |
| **Inlay hints** | yes | See the keys below |
| CodeLens (references / implementations) | yes | |
| Semantic tokens, folding, selection range, document symbols, linked editing (JSX) | yes | |
| tsserver plugins (`@vue/typescript-plugin`, `typescript-svelte-plugin`, ...) | **no** | There is no tsserver, and no plugin model in 7.0 |

The 7.0 post says that since the preview "we've added in missing functionality like auto-imports, expandable hovers, inlay hints, code lenses, go-to-source-definition, JSX linked editing and tag completions... semantic highlighting, 'sort imports', 'remove unused imports', and more are now in."

### Settings keys (important when migrating from ts_ls)

The server pulls `workspace/configuration` for the sections `js/ts`, `typescript`, `javascript` and `editor`. It merges them with precedence `editor < javascript < typescript < js/ts` (`ParseUserPreferences` in https://github.com/microsoft/TypeScript/blob/main/tsc/internal/ls/lsutil/userpreferences.go). The keys are **VS Code-style nested paths** (https://github.com/microsoft/TypeScript/blob/main/tsc/internal/ls/lsutil/userpreferences_generated.go):

```lua
settings = {
  ['js/ts'] = {
    inlayHints = {
      parameterNames = { enabled = 'all', suppressWhenArgumentMatchesName = false }, -- 'none' | 'literals' | 'all'
      parameterTypes = { enabled = true },
      variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
      propertyDeclarationTypes = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
      enumMemberValues = { enabled = true },
    },
  },
}
```

The flat tsserver-style keys that the current `ts_inlay_hints` table passes to ts_ls (`includeInlayParameterNameHints`, `includeInlayVariableTypeHints`, ...) are **not** read from `settings` by tsc, so that table cannot be reused as-is. The lspconfig `tsc` defaults already turn on every category (parameter names set to `'literals'`).

## 5. Vue compatibility

**Current state: vue_ls (Volar hybrid mode) does not work with TS 7. It still needs TS 6 tsserver through `vtsls` or `ts_ls`.**

- **TypeScript team** (7.0 post, "TypeScript and Embedded Languages"): "workflows that use Vue, MDX, Astro, Svelte, and others will likely not yet be able to leverage TypeScript 7 ... tools (such as Volar) which embed TypeScript ... can only currently rely on TypeScript 6.0 ... Projects using Vue, MDX, Astro, Svelte, and others will need to continue using TypeScript 6.0 for now." https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/
- **Vue team** (johnsoncodehk, maintainer, 2026-07-12 on vuejs/language-tools#5381): "All published packages (`vue-tsc`, the language server, the tsserver plugin) still require the TypeScript 6 JS API, because TS 7.0 ships no programmatic API or plugin mechanism. Real tsgo integration is blocked on the API planned for TS 7.1." https://github.com/vuejs/language-tools/issues/5381 . He closed #5381 on 2026-07-23 with [typescript-native-bridge](https://github.com/johnsoncodehk/typescript-native-bridge) as the interim direction. That project is a drop-in replacement for the `typescript` *package* that speeds up `vue-tsc` about 2-3x. It is a CLI/type-check speedup, not a tsgo LSP for Neovim.
- **Vue's Neovim wiki** (current) still prescribes `vtsls` (or `ts_ls`) with `@vue/typescript-plugin` (`location` = the Mason `vue-language-server` path, `languages = {'vue'}`, `configNamespace = 'typescript'`) plus `vim.lsp.enable({'vtsls','vue_ls'})`. https://github.com/vuejs/language-tools/wiki/Neovim . nvim-lspconfig's `vtsls` docs say the same: "Since v3.0.0, the Vue language server requires `vtsls` to support TypeScript." https://github.com/neovim/nvim-lspconfig/blob/master/lsp/vtsls.lua
- **Latest stable Vue LS:** v3.3.14 (2026-10-29), still built on TS 6. https://github.com/vuejs/language-tools/releases

**The path forward (not usable yet):** Vue Language Tools **v4**, draft PR https://github.com/vuejs/language-tools/pull/6170 ("feat: content mapper (v4 alpha)", updated 2026-11-01):

- It type-checks `.vue` through TS 7.1's native `tsc` using a `@vue/content-mapper` that you register in `tsconfig.json` `contentMappers`. "v4 supports TypeScript 7.1 only." `vue-tsc` is replaced by `tsc --runExternalCode`.
- For Neovim/Zed/Sublime it says: "Editors must provide the TypeScript API pipe. The client answers Vue LS's `vue/typescriptApiConnection` request by forwarding `custom/initializeAPISession` to the TS 7.1 language server (`tsc --lsp --stdio`, started with `initializationOptions: { runExternalCode: true }`) ... There is no fallback." It also says "`@vue/typescript-plugin` is removed" and "The server no longer needs TypeScript 5 or 6."
- Known v4 regressions: no formatting of `.vue` script blocks or template expressions, shorthand-rename gaps, no semantic tokens from Vue LS, and others.
- Content mappers themselves ship in TS 7.1 (https://devblogs.microsoft.com/typescript/announcing-typescript-7-1-beta/#content-mappers). The beta post notes `@vue/content-mapper` "is not currently on npm".

So getting "tsgo-only, Vue included" requires three things, none of which have happened as of 2026-11-01: (1) TS 7.1 final ships (expected around late November or December 2026), (2) Vue LS v4 ships, and (3) someone writes Neovim glue for the `vue/typescriptApiConnection` forwarding (nvim-lspconfig's `vue_ls` has nothing for it yet) and starts `tsc` with `init_options = { runExternalCode = true }` and `vue` in its filetypes.

**Same caveat for Astro and Svelte**, which the config also enables. Their TS intelligence inside `.ts` files depends on tsserver plugins too, and the TS 7.0 post lists them with Vue as needing TS 6 for now.

## 6. What this means for the config (input for the map)

1. Replace `lsp/tsgo.lua` (it points at a deleted `$TSGOPATH` build, uses the pre-release `tsgo lsp --stdio` form, and runs root detection at load time) with lspconfig's **`tsc`**: `vim.lsp.enable('tsc')`, with Mason package `tsc` in `ensure_installed`. Remove the `$TSGOPATH`/`ts_ls` fallback and uninstall the deprecated Mason `tsgo` package.
2. Rewrite the inlay hint overrides into the nested `['js/ts'].inlayHints.*` form, or just rely on lspconfig's defaults.
3. Change `'volar'` to `'vue_ls'`. While Vue is in use, the only working option is `vtsls` (Mason) with `@vue/typescript-plugin`, with `filetypes = { 'vue' }` so it does not overlap with `tsc` on `.ts` files. The trade-off is that `.ts` files imported by `.vue` files get tsc while `.vue` files get vtsls on TS 6, so there are two type-checkers for one project. The alternative is to accept no TS intelligence in `.vue` files until Vue LS v4 plus TS 7.1.
4. Use `source.organizeImports` code actions for organize imports. Do not expect refactor code actions (extract, move to file) or type hierarchy from tsc 7.0.
5. Neovim 0.12.6 is the current stable release (https://github.com/neovim/neovim/releases), and the lspconfig `tsc` config works on it (it uses `vim.fs.root` grouping from 0.11.3+). The local machine still runs 0.11.5.
