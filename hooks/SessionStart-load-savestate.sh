#!/usr/bin/env bash
# SessionStart-load-savestate.sh — emit a condensed context block at session
# start so the LLM has current pipeline state without re-reading the whole file.
#
# Reads the save-state markdown at $LC_SAVESTATE_PATH (default:
# ~/Documents/Notes/2. Areas/Work/SAVE-STATE.md).
#
# Never modifies the save-state. Silent no-op if file missing.

set -eu

_ss_path="${LC_SAVESTATE_PATH:-${HOME}/Documents/Notes/2. Areas/Work/SAVE-STATE.md}"

if [ ! -f "${_ss_path}" ]; then
  exit 0
fi

# Extract the first H1, the most recent 5 lines of the session log, and the
# active-contacts count.
_h1="$(grep -m1 '^# ' "${_ss_path}" || true)"
_active="$(awk '/^## Active Contacts/,/^## /{if(/^- /) print}' "${_ss_path}" | wc -l | tr -d ' ')"
_recent="$(awk '/^## Session Log/{found=1;next} found && /^- /{print; n++; if(n==5) exit}' "${_ss_path}")"

printf '## Save-state summary\n'
printf '\n'
[ -n "${_h1}" ] && printf '%s\n\n' "${_h1}"
printf '- Active contacts: %s\n' "${_active}"
printf '- Source: %s\n' "${_ss_path}"
if [ -n "${_recent}" ]; then
  printf '\n### Recent session events\n\n%s\n' "${_recent}"
fi
