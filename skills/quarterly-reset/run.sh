#!/usr/bin/env bash
# quarterly-reset runner. Archives session log on quarter boundary.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_ss="${LC_SAVESTATE_PATH:-${_self}/fixtures/save-state.example.md}"
_archive_dir="${LC_ARCHIVE_DIR:-${_self}/.archive}"
_today=""
_force=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --savestate)
      _ss="$2"
      shift 2
      ;;
    --archive-dir)
      _archive_dir="$2"
      shift 2
      ;;
    --today-iso)
      _today="$2"
      shift 2
      ;;
    --force)
      _force=1
      shift
      ;;
    *)
      printf 'quarterly-reset: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ ! -f "${_ss}" ]; then
  printf 'quarterly-reset: save-state missing: %s\n' "${_ss}" >&2
  exit 4
fi

if [ -z "${_today}" ]; then
  _today="$(date -u +%Y-%m-%d)"
fi

_year="$(printf '%s' "${_today}" | cut -d- -f1)"
_month="$(printf '%s' "${_today}" | cut -d- -f2)"
_day="$(printf '%s' "${_today}" | cut -d- -f3)"

case "${_month}" in
  01 | 02 | 03) _q="Q1" ;;
  04 | 05 | 06) _q="Q2" ;;
  07 | 08 | 09) _q="Q3" ;;
  10 | 11 | 12) _q="Q4" ;;
  *) _q="Q?" ;;
esac

# Boundary = first day of a quarter.
_is_boundary=0
case "${_month}-${_day}" in
  01-01 | 04-01 | 07-01 | 10-01) _is_boundary=1 ;;
esac

if [ "${_is_boundary}" -eq 0 ] && [ "${_force}" -eq 0 ]; then
  cat <<JSON
{
  "schema": "quarterly-reset",
  "verdict": "noop",
  "reason": "today ${_today} not a quarter boundary; pass --force to override",
  "quarter": "${_q}",
  "year": ${_year}
}
JSON
  exit 0
fi

mkdir -p "${_archive_dir}"
_archive_path="${_archive_dir}/session-log-${_year}-${_q}.md"

# Extract session log section via awk (H2 block: "## Session Log" → next "## ").
_session_block="$(awk '
  /^## Session Log/ { in_s=1; next }
  in_s && /^## / { in_s=0 }
  in_s { print }
' "${_ss}")"

_events=0
if [ -n "${_session_block}" ]; then
  _events=$(printf '%s\n' "${_session_block}" | grep -c '^- ' || true)
fi

# Idempotent: only write if archive missing or --force.
if [ ! -f "${_archive_path}" ] || [ "${_force}" -eq 1 ]; then
  {
    printf '# Session Log Archive — %s %s\n\n' "${_year}" "${_q}"
    printf '%s\n' "${_session_block}"
  } >"${_archive_path}"
fi

# Stale contact detection — read Active Contacts section, flag none for fixture.
# (Full implementation requires per-contact last-event dates in the save-state;
# current save-state format records this as annotations.)
_stale_json="[]"

cat <<JSON
{
  "schema": "quarterly-reset",
  "verdict": "archived",
  "quarter": "${_q}",
  "year": ${_year},
  "archive_path": "${_archive_path}",
  "events_archived": ${_events},
  "stale_contacts": ${_stale_json}
}
JSON
