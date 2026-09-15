# AGENTS.md

## What this repository is

A personal Neovim configuration (LazyVim distribution, lazy.nvim plugin manager) for the "ShipGlows" operator. It is both a Neovim config and the host of a custom Lua plugin, `lua/shipglows/`, which implements a privacy-sensitive local email triage pipeline ("Mail Intel" / "Mail Intelligence") on top of Maildir + notmuch + Python bridge scripts.

There is no build system, package manager, or CI. Files are loaded directly by Neovim. The only "build" verification is Neovim loading the config and targeted Lua test scripts.

## Language and conventions

- UI strings, keymap descriptions, and much of the documentation are in **French** (often without accents in code strings, e.g. `"precedent"`). User-facing docs (`Mail Intel.md`, `ShipGlowsUsage.md`, specs) are French. Follow that when adding notifications/descriptions.
- Formatting: `stylua.toml` - 2 spaces, column width 120. Run `stylua .` before finishing.
- `init.lua` only bootstraps lazy.nvim; everything else lives in `lua/config/` (LazyVim overrides: options, keymaps, autocmds, lazy spec) and `lua/plugins/` (one file per plugin spec, imported as `{ import = "plugins" }`).
- `lua/config/lazy.lua` sets `defaults.lazy = true` and `version = false`: custom plugin specs are lazy-loaded by default unless they opt into startup loading, and always pinned to latest git commit (`lazy-lock.json` records versions).

## Custom code: `lua/shipglows/`

- `init.lua` - markdown heading navigation + panel-size presets (`:ShipGlowsPanel1/2/3/Full`), loaded from `lua/config/keymaps.lua` via `require("shipglows").setup()`.
- `clipboard.lua` - governed clipboard: sets `+` and `"` registers, OSC 52 escape when over SSH, and always writes a fallback file to `stdpath("cache")/shipglows-notifications.txt`. Use this module, not raw `setreg`, when copying governed content.
- `mail/` - the Mail Intelligence stack:
  - `config.lua` - all options come from env vars with defaults (`MAIL_INTEL_ROOT`, `MAIL_INTEL_ACCOUNT`, `MAIL_INTEL_FOLDER`, `MAIL_INTEL_LIMIT`, `SHIPGLOWS_PRIVATE_DATA_DIR`, `SHIPGLOWS_MAIL_INTAKE_ROOT`, `NOTMUCH_CONFIG`, `MAIL_INTEL_AI_PROVIDER`, `SHIPGLOWS_PROJECT_INDEX_ROOT`). CLI paths are resolved relative to the repo root via `debug.getinfo`, so the repo location matters at runtime.
  - `reader.lua` - read-only v1 explorer (`:CompetitorMail*` commands, `<leader>mI/mS/mf/ma/mO/my/mb/mA`).
  - `review.lua` - v2 interactive review queue (`:MailIntake`, `<leader>mi`). Split layout: list on top (~24% height), source below. Keybindings: `<CR>` open source, `a` AI classify, `r` AI summarize, `h` governed handoff, `d` trash via IMAP (no confirmation), `y/e/E/x/i` accept/edit/edited/reject/ignore.
  - `ai.lua` - provider-neutral classification layer. Builds a French prompt embedding private project context from `project_index_root` (capped at 8000 chars per file), asks for strict JSON, normalizes it. For Avante ACP providers it passes the local Maildir file path instead of the body (HTTP providers get a bounded body export). Each analysis forces `new_chat = true` so stale ACP sessions don't keep an old model - this is a tested contract, don't remove it.

## External scripts (`scripts/`, Python 3, not Lua)

- `mail-intel` - read-only Maildir bridge: list/search/export via notmuch, JSON or markdown output. It must never mutate mail (no send/delete/archive/move/tag).
- `mail-intake` - review-first bridge: creates metadata-only private queue records under `~/.shipglows/private/data/mail-intake/inbox/`, moves processed ones to `done/`. Idempotent: must not create duplicate pending records for the same source.
- `mail-delete` - the only mail-mutating script: sends a message to Gmail Trash via IMAP. Separate from review `x` (which only removes the queue record).
- `mail-admin` - Gmail labels/filters admin via the official API, with a versioned local registry.

## Hard privacy and safety rules (non-negotiable)

- Raw email bodies live only in the private Maildir (`~/.shipglows/private/data/mail-source/`, outside Git) or in-memory. Queue records under `mail-intake/` are **metadata-only**. Never write raw email content into this repository.
- Handoffs (`h`) carry routing metadata and `source_id` only, never email bodies.
- The pipeline must never send mail or mutate remote inbox state, except `mail-delete`'s explicit trash action.
- Bug records in `bugs/` deliberately contain no raw email content; keep it that way.

## Testing

No test framework. Standalone Lua scripts in `tests/`, each an assertion harness run headlessly, e.g.:

```bash
nvim --headless -l tests/codex-acp-lifecycle.lua
nvim --headless -l tests/mail-ai-avante-new-chat.lua
```

- Tests locate the repo root from their own path and load config files directly (`loadfile` on `lua/plugins/avante.lua`, or `package.path` manipulation to require `shipglows.*`); they stub dependencies by pre-populating `package.loaded`. Follow this pattern for new tests.
- `mail-ai-avante-new-chat.lua` enforces that Avante asks use the configured ACP provider and `new_chat = true`.
- `codex-acp-lifecycle.lua` requires the Codex ACP binary to be installed and executable.
- Manual verification results are logged in `TEST_LOG.md` (fixed field format: Scope/Environment/Tester/Source/Status/Confidence/Result summary/Bug pointer/Evidence pointer/Follow-up). Append entries in the same format after user testing.

## Bugs and specs workflow

- `bugs/BUG-YYYY-MM-DD-NNN.md`: structured bug records with Title/Status/Severity/Story/Fix Attempts/Evidence/Retest History. Update status and retest history there when fixing.
- `shipglows_data/workflow/specs/`: behavior specs with YAML frontmatter (artifact, depends_on, success behavior, privacy constraints). Mail Intelligence features trace back to these specs; consult the relevant spec before changing review/intake behavior.
- `Mail Intel.md` is the authoritative documentation for the mail pipeline (architecture diagram, keybindings, env vars, systemd timer). Update it when behavior changes. Daily scan runs via a user systemd timer (`shipglows-mail-intake.timer`, 07:00 and 14:00 Europe/Paris) that runs `mbsync` + `notmuch new` + `mail-intake scan` only.

## Gotchas

- Buffer naming collisions: source buffers in the review queue must get unique fallback names when the canonical name exists (see BUG-2026-07-12-002, E95 error). Preserve `source_buffer_name` logic.
- `vim.system` callbacks must wrap UI work in `vim.schedule` - existing code does this consistently.
- The mail CLI invocations always pass `--maildir-root` plus the env from `config.system_opts()`; don't rely on ambient env vars.
- Review list line-to-item mapping (`vim.fn.line(".") - 6`) depends on the rendered list header; changing the list format breaks item selection.
- Neovim config reload is `<leader>R` (sources `init.lua`); not everything reloads cleanly, a full restart is the reliable option for plugin spec changes.
