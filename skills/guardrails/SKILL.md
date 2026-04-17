---
name: guardrails
description: Evaluate a proposed action against config/guardrails.yaml rules. Returns verdict (allow/warn/deny) with the specific rule and reason.
trigger: command
command: lc-guardrails
platform: darwin
inputs:
  - name: action
    type: string
    required: true
  - name: slot_hhmm
    type: string
    required: false
  - name: fit_score
    type: integer
    required: false
  - name: channel
    type: string
    required: false
outputs:
  - name: verdict
    type: json
---

# guardrails

Advisory checker: given a proposed action description plus relevant metadata,
evaluates every enabled rule in `config/guardrails.yaml` and returns a verdict.

## Rules evaluated

| Rule                  | Trigger                                              |
|-----------------------|------------------------------------------------------|
| no_morning_meetings   | action=book_slot + slot_hhmm inside start..end       |
| hell_yes_threshold    | action=progress_pipeline + fit_score < threshold     |
| async_over_live       | action=book_slot when channel in prefer_channels     |
| send_verify_required  | action=send + no verify marker                       |
| no_autosend           | action=send + no explicit `--approved` flag          |

## Contract

```json
{
  "schema": "guardrails-verdict",
  "action": "book_slot",
  "verdict": "deny",
  "triggered": [
    {"rule": "no_morning_meetings", "reason": "..."}
  ]
}
```

## Invariants

- Read-only: never mutates state or files.
- Default to **deny** on conflicting advice (operator overrides explicitly).
- No Chrome, no network.
