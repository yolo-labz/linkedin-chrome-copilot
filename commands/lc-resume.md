---
name: lc-resume
description: Resume the job-search pipeline. Reads the save-state markdown and returns top-ranked next actions with owner + channel.
platform: darwin
---

# /lc-resume

Run the `resume-session` skill + the `pipeline-curator` agent in sequence.

## Usage

```
/lc-resume                  # use $LC_SAVESTATE_PATH or default
/lc-resume <path-to-file>   # explicit save-state path
```

## Flow

1. Platform gate refuses non-macOS.
2. `SessionStart-load-savestate` hook (already fired) has emitted a condensed
   summary into context.
3. `skills/resume-session/run.sh` parses the save-state and emits `save-state`
   contract JSON.
4. `pipeline-curator` agent re-ranks and assigns owner + channel.
5. Output: top 3-5 next actions, cited against the save-state.

## Output target

Success criteria SC-003: from hot-key to ranked next-action list in < 30s.

## Example

```
$ /lc-resume
{"schema":"save-state","active_contacts":10,"closed_contacts":3,...}
```
