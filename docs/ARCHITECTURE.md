# Architecture

`linkedin-chrome-copilot` is a Claude Code plugin that packages the operator's
LinkedIn / outreach / scheduling workflow as skills, agents, and slash commands.
It delegates all macOS Chrome automation to the sibling plugin
`yolo-labz/claude-mac-chrome` via `chrome-lib.sh`.

## Layers

```
   ┌─────────────────────────────────────────────────────────┐
   │ Commands (commands/*.md)                                │
   │   /lc-resume  /lc-reply  /lc-book  /lc-tailor  …        │
   └────────────┬────────────────────────────────────────────┘
                │ triggers
   ┌────────────▼────────────────────────────────────────────┐
   │ Skills (skills/<name>/SKILL.md + run.sh)                │
   │   resume-session, draft-reply, clipboard-handoff,       │
   │   send-verify, book-slot, watch-cancellation,           │
   │   tailor-cv, profile-sync, guardrails, quarterly-reset  │
   └────────────┬───────────────────────┬────────────────────┘
                │                       │
   ┌────────────▼──────────┐  ┌─────────▼──────────┐
   │ tools/                 │  │ schemas/            │
   │   platform-gate.sh     │  │   *.schema.json     │
   │   chrome-shim.sh ──────┼──┤                     │
   │   pii-scan.sh          │  │  JSON Schema draft-07│
   └────────────┬───────────┘  └─────────────────────┘
                │ sources
   ┌────────────▼──────────────────────────────────────────┐
   │ Sibling plugin: yolo-labz/claude-mac-chrome           │
   │   chrome-lib.sh (AppleScript + profile catalog)       │
   └───────────────────────────────────────────────────────┘
```

## Boundaries

- **`tools/platform-gate.sh`** is the first non-comment line of every
  skill runner. Refuses non-Darwin. Verifies sibling plugin presence + version.
- **`tools/chrome-shim.sh`** is the only module that sources
  `chrome-lib.sh`. Skills call its `lc_*` wrappers; never call AppleScript
  directly (enforced by `no-raw-applescript` pre-commit hook).
- **`tools/pii-scan.sh`** runs in pre-commit + CI. Hard gate on email, phone,
  Calendly links, magic-login URLs. Allowlist covers `*@example.invalid`,
  synthetic zero-phones.

## Persistence model

- **Canonical save-state**: single markdown file in the operator's vault
  (`$LC_SAVESTATE_PATH`). Read-first, append-last. No database.
- **Local alias map**: `~/.config/linkedin-copilot/aliases.json` — real
  identity only lives here, gitignored in the operator's vault and never in
  this plugin repo.
- **Pipeline events**: appended to the `## Session Log` section of the
  save-state, newest-first.

## Channels & registers

`config/registers.yaml` captures channel-specific tone / length / formatting:

| Channel  | max_chars | notes                               |
|----------|-----------|-------------------------------------|
| linkedin | 400       | concise, Portuguese/English parity  |
| email    | —         | subject-line required, markdown off |
| whatsapp | —         | pt-BR default, casual               |
| github   | —         | markdown allowed, issue/PR context  |
| ats      | —         | rejected (exit 3) — use clipboard   |

## Guardrails

See `config/guardrails.yaml`. Enforced advisory via `skills/guardrails`:

- `no_morning_meetings` (09:00–12:00 BRT deep-work block)
- `hell_yes_threshold` (fit_score ≥ 80)
- `send_verify_required` (DOM re-read within 2000 ms)
- `no_autosend` (operator approval gate)
- `profile_sync_locales` (en-US + pt-BR pair)
- `quarterly_reset` (stale contacts > 60 d at quarter boundary)

## Extensibility

New skills follow the shape:

```
skills/<name>/
  SKILL.md       # frontmatter: name, description, trigger, command, platform
  run.sh         # sources platform-gate.sh as first non-comment line
```

See `docs/EXTEND.md`.
