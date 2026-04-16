---
name: watch-cancellation
description: Scan inbox fixtures for cancellation keywords. Flip affected Slot state to reschedule-pending and add the contact to the hot-priority queue.
trigger: command
platform: darwin
---

# watch-cancellation

Triggered by an inbox check (`lc_check_inboxes`). For each inbound message
matching a cancellation keyword, flip the affected Slot's state to
`reschedule-pending` and emit a `pipeline-event` so the curator surfaces the
contact at the top of the next `/lc-resume`.

## Keywords (EN + PT)

- cancel, canceled, cancelled, reschedule, can't make it, won't work, need to move
- cancelar, remarcar, reagendar, não vou conseguir, precisamos remarcar

## Output

```json
{
  "schema": "pipeline-event",
  "event": "watch-cancellation",
  "alias": "contact-c3",
  "slot_id": "slot-002",
  "state": "reschedule-pending",
  "hot_queue": true
}
```
