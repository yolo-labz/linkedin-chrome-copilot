---
name: profile-sync
description: Open LinkedIn profile-edit tabs for both en-US and pt-BR locales in the operator's LinkedIn Chrome profile. Prep for manual parity edits.
trigger: command
command: lc-profile-sync
platform: darwin
inputs:
  - name: profile
    type: string
    default: $LC_LINKEDIN_PROFILE
    required: false
  - name: section
    type: string
    default: headline
    required: false
outputs:
  - name: opened
    type: json
---

# profile-sync

Open two Chrome tabs — one per locale — so the operator can keep the
LinkedIn profile in parity across en-US and pt-BR.

## Algorithm

1. Source `tools/chrome-shim.sh`.
2. Resolve target profile via `lc_catalog` (refuse unnamed profiles).
3. For each locale in `["en-US", "pt-BR"]`:
   - Compose `https://www.linkedin.com/in/me/edit/<section>/?locale=<locale>`.
   - Call `lc_open_tab profile=<profile> url=<composed>`.
4. Emit JSON summary with the two opened tab fingerprints.

## Invariants

- Never posts, saves, or submits anything — navigation only.
- Refuses if the configured Chrome profile is missing or unnamed.
- Locales are fixed to `en-US` + `pt-BR` per `config/guardrails.yaml#profile_sync_locales`.
- No credential handling — relies on an existing Chrome session.

## Contract

```json
{
  "schema": "profile-sync",
  "profile": "LinkedIn",
  "section": "headline",
  "opened": [
    {"locale": "en-US", "url": "https://www.linkedin.com/in/me/edit/headline/?locale=en-US", "fingerprint": "..."},
    {"locale": "pt-BR", "url": "https://www.linkedin.com/in/me/edit/headline/?locale=pt-BR", "fingerprint": "..."}
  ]
}
```

## Runner

`skills/profile-sync/run.sh` is the entry point.
