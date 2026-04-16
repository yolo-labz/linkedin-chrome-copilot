#!/usr/bin/env bash
# send-verify runner.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"
# shellcheck source=/dev/null
. "${_self}/tools/chrome-shim.sh"

_fp=""
_marker=""
_timeout=2000
_alias=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --fingerprint) _fp="$2"; shift 2 ;;
    --marker) _marker="$2"; shift 2 ;;
    --timeout-ms) _timeout="$2"; shift 2 ;;
    --alias) _alias="$2"; shift 2 ;;
    *) printf 'send-verify: unknown arg %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [ -z "${_fp}" ] || [ -z "${_marker}" ]; then
  printf 'send-verify: usage: run.sh --fingerprint <tab-fp> --marker <substring> [--timeout-ms N] [--alias contact-XX]\n' >&2
  exit 2
fi

_js="(() => { return document.body.innerText.includes(\"${_marker}\") ? \"found\" : \"\"; })()"

_deadline=$(( $(date +%s%3N 2>/dev/null || date +%s)000 / 1 ))
# bash 3.2 lacks %s%3N; fall back to loop with sub-second sleeps.
_start=$(date +%s)
_state="unconfirmed"
while [ "$(( ( $(date +%s) - _start ) * 1000 ))" -lt "${_timeout}" ]; do
  _result="$(lc_execute_js "${_fp}" "${_js}" 2>/dev/null || true)"
  if [ "${_result}" = "found" ]; then
    _state="sent"
    break
  fi
  sleep 0.25
done

_ts="$(date +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')"
cat <<JSON
{"schema":"draft","alias":"${_alias}","state":"${_state}","verified_at":"${_ts}","fingerprint":"${_fp}","marker":"${_marker}","timeout_ms":${_timeout}}
JSON

# Emit separate PipelineEvent on stderr so callers can ingest both.
printf '{"schema":"pipeline-event","event":"send-verify","alias":"%s","state":"%s","ts":"%s"}\n' \
  "${_alias}" "${_state}" "${_ts}" >&2
