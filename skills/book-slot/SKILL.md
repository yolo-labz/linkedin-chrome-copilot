---
name: book-slot
description: Propose ≤ 3 ranked Calendly slots that fit the operator's free-window + guardrails. Every slot carries an explicit timezone label.
trigger: command
command: lc-book
platform: darwin
inputs:
  - name: contact
    type: string
    required: true
  - name: source-url
    type: url
    required: true
outputs:
  - name: slots
    type: json
    schema: schemas/slot.schema.json
---

# book-slot

Parse a Calendly response (fetched separately, or from fixture), intersect
with `free-window.example.json`, apply guardrail rules, rank, emit the top
3. A second invocation `--book <slot-id>` performs the actual booking
(delegated to `chrome-shim.sh lc_execute_js` or a direct POST, outside this
skill's minimal implementation).

## Invariants

- Every slot carries `tz_label` (redundant with `start_utc`) so the operator
  never sees an unlabeled local time.
- Slots inside the deep-work block are rejected — no UI override at install
  defaults.
- Blocked days are hard excludes.
- Fit score considers: distance from deep-work boundary, day-of-week, and
  window fullness.

## Output shape

```json
{
  "schema": "slot",
  "event_type": "...",
  "proposed": [
    {
      "slot_id": "slot-002",
      "start_utc": "2026-04-17T19:30:00Z",
      "local": "2026-04-17T16:30-03:00",
      "tz_label": "BRT (UTC-03:00)",
      "fit_score": 0.92,
      "reasons": ["inside meeting window", "clear of deep-work block"]
    }
  ]
}
```
