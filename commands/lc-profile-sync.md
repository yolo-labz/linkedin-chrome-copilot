---
name: lc-profile-sync
description: Open LinkedIn profile-edit tabs for en-US and pt-BR side-by-side so the operator can keep the profile in parity across locales.
platform: darwin
---

# /lc-profile-sync

## Usage

```
/lc-profile-sync [--profile <chrome-profile-name>] [--section <section>]
```

Default section is `headline`. Other common sections: `about`, `experience`,
`education`, `skills`, `certifications`.

## Flow

1. Platform gate + `chrome-shim.sh` sourcing.
2. Resolve Chrome profile via `lc_catalog`.
3. `skills/profile-sync/run.sh` opens two tabs — one per locale — pointed at
   the same profile section.
4. Operator edits both in parallel.

## Guardrails

- Navigation only. Never clicks Save / Submit.
- Fixed locale pair: `en-US` + `pt-BR` (see `config/guardrails.yaml`).
- Refuses unnamed Chrome profiles (inherited from `chrome-shim.sh`).
