# Coding standards

Read during review. These are judgement calls; mechanical rules are checks in
`tests/check.sh` (stylua, test names matching their spec file, the signed-out
harness), so they aren't repeated here.

## Config

- **One job per module.** A module changes for one reason. When a feature (folding, LSP progress, Copilot) grows past a few lines inside another module, it moves to its own `lua/custom/<feature>.lua` with a `setup()` the owner calls. `lspconfig.lua` owns servers and their attach hooks.
- **One source of truth.** A policy that two places apply (the foldexpr choice, a filetype exclusion list) lives once and both places call it.
- **Lazy-load stubs match the keys.** A spec's `cmd` lists `:Commands` that its keys or the spec itself run, nothing speculative.
- **Match the surrounding style.** Key notation as init.lua writes it (`<CR>`, `<leader>`), `desc` in the `[X]` mnemonic style where which-key shows it, comments that say why, not what.
- **Removing a plugin removes its traces.** Its spec, its lock entry, comments that name it, and any option or capability that only existed for it.

## Tests

- **Assert behavior, never layout.** A test checks what a user could observe: what's loaded, attached, mapped, set, opened, written to disk. It never counts spec fragments, reads a plugin's config table back, or checks an internal key name. When the behavior is costly to trigger, assert its nearest visible effect instead.
- **Leave shared state as you found it.** Specs run in one Nvim, in file order, and later tests reuse fixture buffers. A test that changes a buffer, window, option or client restores it, or works on its own scratch file or `h.sibling_copy`.
- **Wait for a condition, not a duration.** Poll with `vim.wait(ms, cond)`, and keep fixed sleeps to the harness's settle helpers. A slow test is a finding.
- **Every test was red first.** A new check fails with the change reverted. Name the reason in the commit when that wasn't possible.
- **Helpers over repetition.** An assertion shape repeated across spec files becomes an `h.*` helper documented in `tests/README.md`.
