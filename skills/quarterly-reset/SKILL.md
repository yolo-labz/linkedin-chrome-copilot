---
name: quarterly-reset
description: At quarter boundaries, rotate the save-state session log and flag stale contacts. Write-safe — only appends to archive, never drops data.
trigger: command
command: lc-quarterly
platform: darwin
inputs:
  - name: savestate_path
    type: path
    default: $LC_SAVESTATE_PATH
    required: false
  - name: archive_dir
    type: path
    default: $LC_ARCHIVE_DIR
    required: false
  - name: today_iso
    type: string
    required: false
outputs:
  - name: report
    type: json
---

# quarterly-reset

Invoked on a quarter boundary (1 Jan / 1 Apr / 1 Jul / 1 Oct) or manually.

## Algorithm

1. Compute current quarter (`Q1..Q4`) from `--today-iso` or `date -u`.
2. If not at quarter boundary AND `--force` absent, emit `noop` verdict.
3. Read save-state. Extract `## Session Log` block.
4. Write session-log to `${archive_dir}/session-log-<YYYY>-<Qn>.md`
   (create dir if missing). Append-only — never overwrites existing archive.
5. Replace session log in save-state with a header line referencing archive.
6. For each contact in `## Active Contacts`, compute days-since-last-event.
   If > `stale_contact_days`, mark as flagged in output.
7. Never mutates aliases.json or contacts.json.

## Contract

```json
{
  "schema": "quarterly-reset",
  "quarter": "Q2",
  "year": 2026,
  "archive_path": "/.../session-log-2026-Q2.md",
  "stale_contacts": [{"alias": "contact-a1", "days_since_event": 73}],
  "events_archived": 47
}
```

## Invariants

- Idempotent within a day — re-running does not double-archive.
- Never deletes contacts from the save-state.
- No Chrome, no network.
