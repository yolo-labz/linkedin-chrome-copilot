---
name: lc-book
description: Propose + book interview slots from a Calendly URL. Always timezone-labeled, always deep-work-respecting.
platform: darwin
---

# /lc-book

## Usage

```
/lc-book --contact <alias> --source-url <calendly-event-url>
/lc-book --book <slot-id>
```

## Flow

1. Platform gate.
2. First invocation: `skills/book-slot/run.sh` parses the Calendly response
   + free-window, ranks, emits ≤ 3 proposed slots with explicit `tz_label`.
3. Operator picks a slot.
4. Second invocation with `--book <slot-id>` finalizes via `chrome-shim.sh
   lc_execute_js` (click the confirm button in the Calendly tab) + verifies.
5. `skills/watch-cancellation` is called from any subsequent inbox check
   when a message matches a cancellation keyword.

## Guardrails

- No slot inside the deep-work block (default 09:00-12:00 BRT).
- No slot on a `blocked_days` entry.
- Every slot must carry `tz_label`.
