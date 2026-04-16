---
name: send-verify
description: After a send action, re-read the DOM for confirmation. Transitions Draft state to 'sent' only on verified content match; otherwise 'unconfirmed'.
trigger: command
platform: darwin
---

# send-verify

Closed-loop confirmation. A Draft never silently becomes `sent`.

## Flow

1. Caller passes: `--fingerprint <tab-fp> --marker <expected-substring> [--timeout-ms 2000]`.
2. Poll the DOM via `lc_execute_js` for the marker substring within the
   thread's latest sent message area.
3. If found → emit Draft JSON with `state: sent`.
4. If timeout → emit Draft JSON with `state: unconfirmed`, prompt the
   operator to verify manually.
5. Append a `send-verify` PipelineEvent either way.

## Guardrail

The default timeout of 2000ms is configurable via `config/guardrails.yaml`
`send_verify_required.timeout_ms`. Do not raise without operator consent.
