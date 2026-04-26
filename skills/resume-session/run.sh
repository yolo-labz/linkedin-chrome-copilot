#!/usr/bin/env bash
# resume-session runner. Parses save-state markdown and emits summary JSON.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_ss_path="${1:-${LC_SAVESTATE_PATH:-${HOME}/Documents/Notes/2. Areas/Work/SAVE-STATE.md}}"

if [ ! -f "${_ss_path}" ]; then
  cat >&2 <<EOF
resume-session: save-state not found at ${_ss_path}

Bootstrap:
  export LC_SAVESTATE_PATH=<path-to-your-save-state.md>
  # or accept the default ~/Documents/Notes/2. Areas/Work/SAVE-STATE.md

A fixture lives at fixtures/save-state.example.md for demonstration.
EOF
  exit 7
fi

# Count sections. State-flag awk avoids the range-pattern self-match bug:
# `/^## Active Contacts/,/^## /` collapses to a single line because the
# start line also matches `^## `.
_active="$(awk '/^## Active Contacts/{f=1; next} /^## /{f=0} f && /^- /' "${_ss_path}" | wc -l | tr -d ' ')"
_closed="$(awk '/^## Closed Contacts/{f=1; next} /^## /{f=0} f && /^- /' "${_ss_path}" | wc -l | tr -d ' ')"

# Days since latest session-log entry.
_latest_ts="$(awk '/^## Session Log/{found=1;next} found && /^- [0-9]{4}-[0-9]{2}-[0-9]{2}/{print $2; exit}' "${_ss_path}")"
_latest_date="${_latest_ts%%T*}"
if [ -n "${_latest_date}" ]; then
  # POSIX-compatible day delta via date arithmetic (GNU date only; fall back to 0).
  if _now_epoch="$(date +%s 2>/dev/null)" \
    && _then_epoch="$(date -j -f '%Y-%m-%d' "${_latest_date}" +%s 2>/dev/null)"; then
    _days=$(((_now_epoch - _then_epoch) / 86400))
  elif _then_epoch="$(date -d "${_latest_date}" +%s 2>/dev/null)"; then
    _now_epoch="$(date +%s)"
    _days=$(((_now_epoch - _then_epoch) / 86400))
  else
    _days=0
  fi
else
  _days=0
fi

# Hot priorities.
_hot_json="$(awk '
  BEGIN { in_hot=0; n=0 }
  /^## Hot Priorities/ { in_hot=1; next }
  in_hot && /^## / { in_hot=0 }
  in_hot && /^[0-9]+\. / {
    line=$0
    sub(/^[0-9]+\.[[:space:]]*/, "", line)
    alias=line; sub(/[[:space:]]+—.*$/, "", alias)
    action=line; sub(/^[^—]+—[[:space:]]*/, "", action)
    gsub(/"/, "\\\"", action)
    printf "%s{\"alias\":\"%s\",\"action\":\"%s\",\"owner\":\"operator\",\"rank\":%d}", (n>0?",":""), alias, action, n+1
    n++
  }
' "${_ss_path}")"

# Next actions: same as hot priorities for MVP.
_next_json="${_hot_json}"

# Emit JSON.
cat <<JSON
{
  "schema": "save-state",
  "source": "${_ss_path}",
  "active_contacts": ${_active},
  "closed_contacts": ${_closed},
  "days_since_update": ${_days},
  "hot_priorities": [${_hot_json}],
  "next_actions": [${_next_json}]
}
JSON

# Append PipelineEvent (skip in dry-run when save-state is the fixture).
case "${_ss_path}" in
  */fixtures/*) exit 0 ;;
esac

_ts="$(date +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')"
printf '\n- %s resume-session emitted %d next actions\n' "${_ts}" "$(printf '%s' "${_hot_json}" | tr -cd ',' | wc -c | awk '{print $1+1}')" >>"${_ss_path}"
