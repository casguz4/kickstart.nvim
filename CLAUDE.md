## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues (casguz4/kickstart.nvim) via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Checks

`tests/check.sh` runs stylua and the headless harness (`tests/README.md` explains the harness). Review rules live in `CODING_STANDARDS.md`.
