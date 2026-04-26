#!/usr/bin/env bash
# watch-cancellation runner. Takes an inbox message on stdin or via --file.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_alias=""
_slot=""
_file=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --alias)
      _alias="$2"
      shift 2
      ;;
    --slot)
      _slot="$2"
      shift 2
      ;;
    --file)
      _file="$2"
      shift 2
      ;;
    *)
      printf 'watch-cancellation: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -n "${_file}" ]; then
  _msg="$(cat "${_file}")"
else
  _msg="$(cat)"
fi

_re='(cancel|canceled|cancelled|reschedule|can.?t make it|won.?t work|need to move|cancelar|remarcar|reagendar|n.o vou conseguir|precisamos remarcar)'
if printf '%s' "${_msg}" | grep -iE "${_re}" >/dev/null 2>&1; then
  _state="reschedule-pending"
  _hot=true
else
  _state="confirmed"
  _hot=false
fi

_ts="$(date +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')"
cat <<JSON
{"schema":"pipeline-event","event":"watch-cancellation","alias":"${_alias}","slot_id":"${_slot}","state":"${_state}","hot_queue":${_hot},"ts":"${_ts}"}
JSON
