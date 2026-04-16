---
name: clipboard-handoff
description: Push draft body to the macOS clipboard via pbcopy and focus the correct Chrome tab. Last-resort path when DOM insertion is blocked by React-locked UIs.
trigger: command
platform: darwin
---

# clipboard-handoff

1. Call `pbcopy` with the draft body on stdin.
2. Resolve the right Chrome tab via `chrome-shim.sh lc_fingerprint` from
   URL pattern + profile name.
3. Call `lc_focus_tab` to raise it.
4. Append a `clipboard-handoff` PipelineEvent.

The operator pastes with ⌘V. Send-verify runs after.

## Never

- Never upload clipboard content anywhere.
- Never clear the clipboard after — the operator may re-paste.
