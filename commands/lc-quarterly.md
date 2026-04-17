---
name: lc-quarterly
description: Run the quarterly reset — archive session log, flag stale contacts.
platform: darwin
---

# /lc-quarterly

## Usage

```
/lc-quarterly                 # no-op unless today is a quarter boundary
/lc-quarterly --force         # archive now (useful for mid-quarter rotations)
/lc-quarterly --today-iso 2026-04-01
```

## Flow

1. Platform gate.
2. `skills/quarterly-reset/run.sh` detects quarter boundary (or honors `--force`).
3. Archives `## Session Log` block to `${LC_ARCHIVE_DIR}/session-log-YYYY-Qn.md`.
4. Flags stale contacts (> `stale_contact_days` since last event).
5. Emits JSON summary with archive path + counts.

## Guardrails

- Idempotent: re-running the same day is a no-op unless `--force`.
- Append-only: never overwrites an existing archive (unless `--force`).
- Never deletes contacts or mutates aliases.
