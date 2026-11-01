# LSP coverage for current lint/format jobs

Ticket: casguz4/kickstart.nvim#8 (map #4). Researched 2026-11-01 against primary sources: nvim-lspconfig `lsp/*.lua` on `master`, the mason-registry `package.yaml` files, upstream READMEs, changelogs and source.

Target: Neovim 0.12 (latest is v0.12.6, released 2026-10-09). LSP-first, with nvim-lint/conform kept only where no mature server exists.

## TL;DR

| Job today | LSP replacement | lspconfig name | Mason package | Verdict |
|---|---|---|---|---|
| eslint_d (js/ts/jsx/tsx/vue) | vscode-eslint-language-server | `eslint` | `eslint-lsp` | **Replace.** Mature. Diagnostics, code actions and `:LspEslintFixAll` on save. Already enabled. **Needs a lspconfig update** for ESLint 10. |
| stylelint (css/scss/less) | official `@stylelint/language-server` | `stylelint_lsp` | `stylelint-language-server` (`stylelint-lsp` is deprecated) | **Replace**, but set `settings.stylelint.validate` to include `scss` and `less`. Fix-all via `:LspStylelintFixAll`. |
| jsonlint (json) | vscode-json-language-server + SchemaStore.nvim | `jsonls` | `json-lsp` | **Replace.** Strict superset: syntax plus JSON Schema. Already enabled. |
| yamllint (yaml) | (none for yamllint's style rules) | `yamlls` | `yaml-language-server` | **Partial.** yamlls covers syntax and schema but not yamllint style rules. Add yamlls, and keep yamllint in nvim-lint only if you want the style rules. |
| markdownlint (md) | rumdl | `rumdl` | `rumdl` | **Replace, with a beta caveat.** It runs all 53 markdownlint rules and reads `.markdownlint*` configs, but has no JS custom rules. marksman stays for navigation. |
| prettierd/prettier (all web ft) | no mature Prettier LSP | (`oxfmt`, `biome`, `efm`) | (`oxfmt`, `biome`, `efm`) | **Keep conform.** The servers' own formatters are not Prettier. |
| stylua (lua) | `stylua --lsp` | `stylua` | `stylua` | **Replace** (StyLua 2.2.0+). Same binary, same `.stylua.toml`. Prefer it over lua_ls's EmmyLuaCodeStyle formatter. |

Net: eslint, stylelint, jsonlint, markdownlint and stylua can move to LSP. yamllint is a partial gap, kept only for its style rules. Prettier stays in conform for every filetype. If a project uses Biome or oxfmt, their LSPs can take over formatting there.

---

## 1. eslint_d → `eslint` (vscode-eslint-language-server)

- **lspconfig:** `eslint`. Its filetypes include javascript, javascriptreact, typescript, typescriptreact, vue, svelte and astro. It provides a buffer command `LspEslintFixAll`, and its docs show wiring that command to a `BufWritePre` autocmd for fix-all on save. Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/eslint.lua
- **Mason:** `eslint-lsp` → `pkg:npm/vscode-langservers-extracted@4.10.0`, with `neovim.lspconfig: eslint`. Source: https://github.com/mason-org/mason-registry/blob/main/packages/eslint-lsp/package.yaml
- **Settings in lspconfig:** `codeActionOnSave`, `format = true` and `workingDirectory = { mode = 'auto' }`. It also supports monorepos with one server instance and Yarn PnP via `yarn exec`.
- **ESLint 10 gotcha:** older lspconfig always set `experimental.useFlatConfig = true` when a flat config file existed. That setting makes the server load `eslint/use-at-your-own-risk`, which ESLint 10 removed, so validation silently turned off. This was fixed in nvim-lspconfig PR #4329, merged 2026-02-27.
  - **This repo's `lazy-lock.json` pins nvim-lspconfig at `5a855bc` (2026-02-21), which predates the fix.** The local `lsp/eslint.lua` still forces `useFlatConfig = true`.
  - Update nvim-lspconfig before relying on the eslint LSP with ESLint 10 (latest is 10.14.0).
  - Sources: https://github.com/neovim/nvim-lspconfig/issues/4318, https://github.com/neovim/nvim-lspconfig/pull/4329
- **Staleness caveat:** `vscode-langservers-extracted` was last published 2024-05-08 (v4.10.0), while upstream vscode-eslint is at 3.0.34 (2026-07-16). The server works with ESLint 10 once lspconfig is fixed, but newer server features such as bulk suppression are missing. Sources: https://www.npmjs.com/package/vscode-langservers-extracted, https://github.com/microsoft/vscode-eslint/blob/main/CHANGELOG.md
- **Lost vs eslint_d:**
  - eslint_d falls back to a bundled ESLint (v10) when the project has none. The LSP needs ESLint resolvable from the project; otherwise it sends `eslint/noLibrary` and does not lint.
  - lspconfig's `root_dir` also requires an ESLint config file.
  - Speed is about the same, since both are long-running daemons. The LSP adds lint-as-you-type, where nvim-lint ran on BufEnter, BufWritePost and InsertLeave.
  - Config compatibility is identical: both use the project's ESLint and config.
  - Source: https://github.com/mantoni/eslint_d.js#readme
- **Interaction:** with `format = true` the server advertises document formatting, which runs ESLint fixes. If conform ever falls back to LSP formatting for these filetypes, filter by client. Keep prettier as the formatter and eslint for fix-all.

## 2. stylelint → `stylelint_lsp` (official `@stylelint/language-server`)

- **lspconfig:** `stylelint_lsp`. Since 2026-03-26 (commit "feat(stylelint)!: migrate to stylelint-language-server", #4351) it runs `stylelint-language-server --stdio` from the official `stylelint/vscode-stylelint` repo. It previously used the community `bmatcuk/stylelint-lsp`.
  - Filetypes: astro, css, html, less, scss, vue.
  - `root_dir` attaches only when a stylelint config, or a `stylelintConfig` key in `package.json`, exists.
  - It provides `:LspStylelintFixAll`, which runs `stylelint.applyAutoFix`.
  - **Default `settings.stylelint.validate = { 'css', 'postcss' }`, so scss and less are NOT linted unless you override it** (for example `{ 'css', 'postcss', 'scss', 'less' }`).
  - Sources: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/stylelint_lsp.lua, https://github.com/stylelint/vscode-stylelint#readme
  - The local plugin copy (Feb 2026) still has the old bmatcuk config, so update lspconfig.
- **Mason:**
  - `stylelint-language-server` → `pkg:npm/@stylelint/language-server@1.1.1`, with `neovim.lspconfig: stylelint_lsp`. Source: https://github.com/mason-org/mason-registry/blob/main/packages/stylelint-language-server/package.yaml
  - `stylelint-lsp` is deprecated: "deprecated in favor of stylelint-language-server", since 2026-03-27. Source: https://github.com/mason-org/mason-registry/blob/main/packages/stylelint-lsp/package.yaml
- **Maturity:** official Stylelint org package, tested against Stylelint 14–17, and supports `source.fixAll.stylelint`. Source: https://github.com/stylelint/vscode-stylelint/tree/main/packages/language-server
- **Lost vs CLI:**
  - The server "resolves [Stylelint] from the workspace directory", then falls back to a globally installed copy, and does not lint if it finds neither. The Mason `stylelint` package may not count as "global", so this is effectively a project-local requirement.
  - Config files are the same (`.stylelintrc*` / `stylelint.config.*`).
  - It gains lint-as-you-type and fix-all.
- **Note:** `cssls` (already enabled) does its own CSS/SCSS/Less validation with VS Code rules. It does not replace stylelint rules.

## 3. jsonlint → `jsonls` (+ SchemaStore.nvim)

- **lspconfig:** `jsonls` (`vscode-json-language-server --stdio`). Filetypes are json and jsonc, and `init_options.provideFormatter = true`. Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/jsonls.lua
- **Mason:** `json-lsp` → `vscode-langservers-extracted@4.10.0`. Source: https://github.com/mason-org/mason-registry/blob/main/packages/json-lsp/package.yaml
- **SchemaStore:** `b0o/SchemaStore.nvim` (active, last pushed 2026-10-30) supplies `settings.json.schemas` (and `yaml.schemas`). Source: https://github.com/b0o/SchemaStore.nvim
- **Lost vs jsonlint:** nothing that matters. jsonlint only checks syntax, and jsonls covers syntax plus schema validation, completion and hover. jsonlint can be removed from nvim-lint and Mason.
- Formatting stays with prettier through conform. jsonls's formatter is VS Code's jsonc formatter, not Prettier.

## 4. yamllint → `yamlls` (partial)

- **lspconfig:** `yamlls` (`yaml-language-server --stdio`). Filetypes include yaml, yaml.docker-compose, yaml.gitlab and yaml.helm-values. lspconfig forces `yaml.format.enable = true` and `documentFormattingProvider = true`. Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/yamlls.lua
- **Mason:** `yaml-language-server` → `pkg:npm/yaml-language-server@2.0.0` (2026-10-16), with `neovim.lspconfig: yamlls`. Source: https://github.com/mason-org/mason-registry/blob/main/packages/yaml-language-server/package.yaml
- **What it validates:**
  - YAML syntax, using eemeli/yaml since 1.0 with strict spec enforcement. Syntax errors are reported even with schemas off.
  - JSON Schema (draft-04/07/2019-09/2020-12), through modelines or `yaml.schemas` / SchemaStore.
  - A few style options: `yaml.style.flowMapping`, `yaml.style.flowSequence` and `yaml.keyOrdering`.
  - Source: https://github.com/redhat-developer/yaml-language-server#readme
- **Lost vs yamllint:** yamllint's style rules (line-length, truthy, indentation, comments, document-start, and so on) and its `.yamllint` config. No LSP covers them. If you want those rules, keep `yamllint` in nvim-lint as the gap filler. Otherwise yamlls alone is enough for schema-driven YAML.
- **Formatting:** yamlls formats with a **bundled Prettier** (`prettier/standalone` + `prettier/plugins/yaml`). It is configured only through `yaml.format.*` settings and does not read `.prettierrc`. Keep conform's prettierd for yaml if project `.prettierrc` must apply. Sources: https://github.com/redhat-developer/yaml-language-server/blob/main/src/languageservice/services/yamlFormatter.ts, https://github.com/redhat-developer/yaml-language-server/blob/main/package.json
- `yamlls` is **not currently enabled** in `lua/custom/plugins/lspconfig.lua` and `yaml-language-server` is not in `MASON_ENSURED`.

## 5. markdownlint → `rumdl` (marksman keeps navigation)

- **lspconfig:** `rumdl` (`rumdl server`, filetype markdown). Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/rumdl.lua
- **Mason:** `rumdl` → `pkg:github/rvben/rumdl@v0.3.2` (2026-10-28), with `neovim.lspconfig: rumdl`. Source: https://github.com/mason-org/mason-registry/blob/main/packages/rumdl/package.yaml
- **LSP capabilities:** diagnostics as you type, quick-fix code actions, document and range formatting, and an `enableAutoFix` setting for fixing on save. It also has link completion, hover, go-to-definition, references and rename. Those overlap marksman and can be turned off with `init_options` (`enableLinkCompletions = false`, `enableLinkNavigation = false`, `enableSymbols = false`). Source: https://rumdl.dev/lsp/
- **markdownlint compatibility:**
  - It implements all 53 markdownlint rules, plus 37 of its own (90 total).
  - It auto-discovers `.markdownlint.{json,jsonc,yaml,yml}` and `.markdownlint-cli2.{jsonc,yaml,yml}`; for cli2 files it uses `config` and `ignores`.
  - It honors `markdownlint-disable`/`enable` comments.
  - Sources: https://rumdl.dev/markdownlint-comparison/, https://github.com/rvben/rumdl
- **Lost vs markdownlint-cli:**
  - No JavaScript custom rules or plugins.
  - No cli2 `globs` or output formatters.
  - Some rules differ by design: MD004, MD005/MD007, MD013, MD027, MD029, MD037 and MD051.
  - The project calls itself **Beta** (0.x). It gains speed from Rust and incremental caching, though the project gives no hard numbers in text.
- **marksman scope:** completion, go-to-definition, references, rename, and diagnostics **only for wiki-links**: broken references and duplicate or ambiguous headings. It does no style linting and no formatting, so it is not a markdownlint replacement. It complements rumdl. Source: https://github.com/artempyanykh/marksman#readme
- **Other markdown servers in lspconfig:** `markdown_oxide` (PKM/navigation), `remark_ls` and `vale_ls`. None of them is a markdownlint-rule server.
- **Formatting:** `rumdl fmt` applies markdownlint-rule fixes. It is not Prettier's markdown style, so keep prettierd for markdown formatting if you want Prettier output. If you do, make sure rumdl's `enableAutoFix` and Prettier don't fight; for example, MD013 line length versus Prettier `proseWrap`.

## 6. prettierd / prettier (js, ts, jsx, tsx, vue, css, scss, less, html, json, jsonc, yaml, markdown) → keep conform

There is **no mature Prettier language server**:
- `@daliusd/prettier-lsp` is v0.4.0, a single release (2025-11-21), about 40 downloads a month, and not in Mason. Compare prettierd at about 19.9k a month. Sources: https://www.npmjs.com/package/@daliusd/prettier-lsp, https://www.npmjs.com/package/@fsouza/prettierd
- **efm-langserver** (`efm` / Mason `efm`) or `diagnosticls` could wrap prettierd as an LSP. That only moves the CLI behind a generic LSP shim and is no gain over conform.

The servers' built-in formatters are **not Prettier**, so switching to them changes output:
- `cssls` and `html` use **js-beautify** (vscode-css-languageservice / vscode-html-languageservice depend on `js-beautify`). Sources: https://github.com/microsoft/vscode-css-languageservice/blob/main/package.json, https://github.com/microsoft/vscode-html-languageservice/blob/main/package.json
- `jsonls` uses the jsonc-parser formatter.
- `ts_ls`/`tsgo` use the TypeScript formatter.
- `yamlls` uses bundled Prettier but ignores `.prettierrc` (section 4).
- `rumdl` uses its own markdown formatter.

Prettier-compatible LSP alternatives (opt-in per project):
- **oxfmt** (`oxfmt` / Mason `oxfmt` 0.75.0, `oxfmt --lsp`)
  - Covers js/ts/jsx/tsx, json/jsonc/json5, yaml, toml, html, vue, css/scss/less, graphql, markdown/mdx and handlebars.
  - Claims to be about 30x faster than Prettier and tested against Prettier's test suite.
  - Does **not** read `.prettierrc` at runtime. You migrate with `oxfmt --migrate prettier` to `.oxfmtrc.json`.
  - No Prettier plugins (a few, such as tailwind, are built in). The default `printWidth` is 100.
  - lspconfig sets `workspace_required` and attaches only where `.oxfmtrc.json`/`.jsonc` (or an oxfmt `package.json` entry) exists. Pre-1.0.
  - Sources: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/oxfmt.lua, https://oxc.rs/docs/guide/usage/formatter.html, https://oxc.rs/docs/guide/usage/formatter/migrate-from-prettier.html
- **Biome** (`biome` / Mason `biome` 2.6.4, `biome lsp-proxy`)
  - Formats and lints JS/TS/JSX/TSX, JSON/JSONC, CSS, SCSS, YAML, GraphQL and Markdown.
  - HTML formatting is experimental and needs opt-in. Vue, Svelte and Astro are experimental.
  - **Less is not listed.**
  - lspconfig attaches only when `biome.json(c)` exists. Biome uses its own config, not `.prettierrc`, `.eslintrc` or `.stylelintrc`; it has migrate commands for ESLint and Prettier configs.
  - It is a whole-toolchain switch per project, not a drop-in for this config.
  - Sources: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/biome.lua, https://github.com/biomejs/website/blob/main/src/content/docs/en/introduction/language-support.mdx

**Recommendation:** keep `prettierd` → `prettier` in conform for all listed filetypes. If a repo ships `biome.json` or `.oxfmtrc.json`, let that LSP format there; conform's `lsp_format` option and the lspconfig root-dir gating make this per-project. Disable the formatting capability on cssls, html, jsonls and yamlls, or make sure conform never falls back to them, so they don't override Prettier.

## 7. stylua → `stylua` (StyLua's built-in LSP), not lua_ls's formatter

- **lspconfig:** `stylua` (`stylua --lsp`, filetype lua, root markers `.stylua.toml`, `stylua.toml`, `.editorconfig`). Source: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/stylua.lua
- **Mason:** `stylua` (`pkg:github/johnnymorganz/stylua@v2.6.0`, with `neovim.lspconfig: stylua`). This is the same package already used for conform, so no new binary is needed. Source: https://github.com/mason-org/mason-registry/blob/main/packages/stylua/package.yaml
- **Since:**
  - StyLua 2.2.0 (2025-09-14): "StyLua can now run in a language server mode".
  - 2.3.0 added range formatting, minimal-diff edits, workspace-root config search, `.styluaignore` support and the `respect_editor_formatting_options` init option.
  - It answers `textDocument/formatting` and `rangeFormatting`.
  - Sources: https://github.com/JohnnyMorganz/StyLua/blob/main/CHANGELOG.md, https://github.com/JohnnyMorganz/StyLua#readme
- **Lost vs CLI:** nothing. It is the same engine and the same `.stylua.toml`.
- **lua_ls built-in formatting (EmmyLuaCodeStyle):** configured via `.editorconfig` or `Lua.format.defaultConfig`, and it does **not** read `.stylua.toml`. Its output differs from StyLua, and most Neovim-plugin repos (kickstart included) ship `.stylua.toml`. If you use the stylua LSP, set `Lua.format.enable = false` on lua_ls, or filter by client, so the two don't both format. Source: https://luals.github.io/wiki/formatter/
- `emmylua_ls` (Mason `emmylua_ls`) is an alternative Lua server, but not relevant to formatting here.

---

## Concrete migration sketch (for the implementation ticket)

- **Mason (`MASON_ENSURED`):**
  - Add `stylelint-language-server`, `yaml-language-server` and `rumdl`.
  - Drop `eslint_d`, `jsonlint`, `markdownlint` and `stylelint`. Keep `stylelint` only if a global binary is wanted as the LSP's fallback.
  - Keep `yamllint` only if you keep its style rules.
  - Keep `prettier`, `prettierd` and `stylua`.
- **`vim.lsp.enable`:** add `stylelint_lsp`, `yamlls`, `rumdl` and `stylua`. Keep `eslint`, `jsonls`, `cssls`, `html` and `marksman`. (Marksman is installed but not in the enable list today.)
- **Server settings:**
  - `stylelint_lsp`: `settings.stylelint.validate = { 'css', 'postcss', 'scss', 'less' }`.
  - `jsonls`/`yamlls`: SchemaStore schemas.
  - `lua_ls`: `Lua.format.enable = false`.
  - `rumdl`: turn off link and symbol features so marksman owns navigation.
- **Fix-all on save:** a `BufWritePre` that runs `LspEslintFixAll` and `LspStylelintFixAll`. Or, in Neovim 0.12, `vim.lsp.buf.code_action({ context = { only = { 'source.fixAll.eslint' } }, apply = true })`.
- **nvim-lint:** keep only `yaml = { 'yamllint' }`, or remove the plugin entirely.
- **conform:** keep prettier for the web filetypes. Remove `lua = { 'stylua' }` and let `lsp_format = 'fallback'` reach the stylua LSP, or keep conform's stylua, since they are identical.
- **Update nvim-lspconfig** (lockfile `5a855bc` predates the ESLint-10 fix and the stylelint server migration).
