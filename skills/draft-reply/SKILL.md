---
name: draft-reply
description: Produce a channel-aware Draft reply to a contact. Picks register by channel; falls back to clipboard-only access when DOM re-read fails.
trigger: command
command: lc-reply
platform: darwin
inputs:
  - name: alias
    type: string
    required: true
  - name: channel
    type: enum[linkedin,email,whatsapp,ats,github]
    required: true
outputs:
  - name: draft
    type: json
    schema: schemas/draft.schema.json
---

# draft-reply

Read `fixtures/contacts.example.json` (or the operator's live contact store)
for the given alias, pick the register from `config/registers.yaml` based on
channel, and emit a `draft` contract JSON with `state: pending`.

## Invariants

- Never emit a real name — only the alias is visible in committed artifacts.
- LinkedIn DM caps at 400 chars (hard).
- WhatsApp defaults to pt-BR unless the thread's language is already English.
- ATS channel is auto-form only — `draft-reply` refuses with a message
  directing the operator to the ATS form fields instead.
- `state` starts `pending`; `send-verify` is the only path to `sent`.
- If `chrome-shim.sh lc_execute_js` fails a re-read probe on the compose
  element, the access_method flips to `clipboard-only`.
