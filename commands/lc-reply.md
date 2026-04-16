---
name: lc-reply
description: Draft a reply to a contact, hand off via clipboard if React-locked, verify on send.
platform: darwin
---

# /lc-reply

Compose → approve → deliver → verify.

## Usage

```
/lc-reply --contact <alias> [--channel linkedin|email|whatsapp|github]
```

If `--channel` is omitted, the channel is looked up from the contact record.

## Flow

1. Platform gate.
2. `skills/draft-reply/run.sh` produces a Draft JSON (state: pending).
3. `outreach-drafter` agent refines the body within register limits.
4. Operator approves. If approved:
   - **Direct path**: run inline DOM insertion via `chrome-shim.sh lc_execute_js`.
   - **Clipboard-only path**: `skills/clipboard-handoff/run.sh` pipes the body
     to `pbcopy` and focuses the target tab. Operator pastes with ⌘V.
5. Operator confirms the send in the Chrome UI.
6. `skills/send-verify/run.sh` polls the DOM for the marker. Draft transitions
   to `sent` on match, `unconfirmed` on timeout. No silent promotion.

## Register references

See `config/registers.yaml` for per-channel tone and char caps.
