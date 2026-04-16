---
name: resume-session
description: Parse the operator's persistent save-state markdown and emit the top ranked next actions with owner + channel. No network calls; reads a local file.
trigger: command
command: lc-resume
platform: darwin
inputs:
  - name: savestate_path
    type: path
    default: $LC_SAVESTATE_PATH
    required: false
outputs:
  - name: summary
    type: json
    schema: schemas/save-state.schema.json
---

# resume-session

Parse the save-state, count active/closed contacts, compute days-since-update,
and emit JSON conforming to the `save-state` contract. Appends a
`resume-session` PipelineEvent to the session log (append-only).

## Contract

```json
{
  "active_contacts": 10,
  "closed_contacts": 3,
  "days_since_update": 0,
  "hot_priorities": [
    {"alias": "contact-c3", "action": "confirm-slot", "channel": "whatsapp", "owner": "operator"}
  ],
  "next_actions": [
    {"alias": "...", "action": "...", "channel": "...", "owner": "operator", "rank": 1}
  ]
}
```

## Invariants

- Never writes to the save-state until **after** emitting the summary.
- Sources `tools/platform-gate.sh` as the first non-comment line.
- No Chrome calls — pure local file parsing.
- Refuses if save-state file missing; offers bootstrap instructions.

## Runner

`skills/resume-session/run.sh` is the executable entry point invoked by the
command runner. See that file for the parser.
