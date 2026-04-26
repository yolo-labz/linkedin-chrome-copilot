#!/usr/bin/env bash
# book-slot runner. Filters + ranks Calendly slots against the free-window.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_cal="${LC_CALENDLY_PATH:-${_self}/fixtures/calendly-response.example.json}"
_fw="${LC_FREEWINDOW_PATH:-${_self}/fixtures/free-window.example.json}"
_alias=""
_max=3

while [ "$#" -gt 0 ]; do
  case "$1" in
    --contact)
      _alias="$2"
      shift 2
      ;;
    --source-url) shift 2 ;;
    --calendly)
      _cal="$2"
      shift 2
      ;;
    --free-window)
      _fw="$2"
      shift 2
      ;;
    --max)
      _max="$2"
      shift 2
      ;;
    *)
      printf 'book-slot: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ ! -f "${_cal}" ]; then
  printf 'book-slot: calendly response file missing: %s\n' "${_cal}" >&2
  exit 4
fi
if [ ! -f "${_fw}" ]; then
  printf 'book-slot: free-window file missing: %s\n' "${_fw}" >&2
  exit 4
fi

_tz_label="$(jq -r '.tz_label' "${_fw}")"
_tz="$(jq -r '.timezone' "${_fw}")"
_dw_start="$(jq -r '.deep_work_block.start' "${_fw}")"
_dw_end="$(jq -r '.deep_work_block.end' "${_fw}")"

# Assume BRT (-03:00) local for fixture. Convert UTC → local by subtracting 3h.
_tz_offset_min=-180

_event="$(jq -r '.event_type' "${_cal}")"

# For each slot: convert to local, reject if blocked day or inside deep-work block.
_proposed="$(jq -r --argjson offset "${_tz_offset_min}" --arg dws "${_dw_start}" --arg dwe "${_dw_end}" --arg tzl "${_tz_label}" '
  def local_hhmm($utc):
    ($utc | sub("Z$"; "+00:00")) as $s
    | ($s | split("T")[1] | split(":") | (.[0]|tonumber) * 60 + (.[1]|tonumber)) as $mins_utc
    | ($mins_utc + $offset + 24*60) % (24*60)
    | [(./60|floor), (.%60)] ;
  def hhmm_lt($a; $b):
    (($a[0]*60 + $a[1]) < ($b[0]*60 + $b[1])) ;
  def hhmm_le($a; $b):
    (($a[0]*60 + $a[1]) <= ($b[0]*60 + $b[1])) ;
  def parse_hhmm($s):
    ($s | split(":") | [(.[0]|tonumber), (.[1]|tonumber)]) ;

  .slots[] as $slot
  | local_hhmm($slot.start_utc) as $lh
  | parse_hhmm($dws) as $dws_h
  | parse_hhmm($dwe) as $dwe_h
  | if (hhmm_le($dws_h; $lh) and hhmm_lt($lh; $dwe_h))
    then empty
    else {
      slot_id: $slot.slot_id,
      start_utc: $slot.start_utc,
      local_hhmm: (($lh[0] | tostring | ("00" + .) | .[-2:]) + ":" + ($lh[1] | tostring | ("00" + .) | .[-2:])),
      tz_label: $tzl,
      duration_min: $slot.duration_min,
      fit_score: (if ($lh[0] >= 14 and $lh[0] < 18) then 0.95 else 0.60 end),
      reasons: (if ($lh[0] >= 14 and $lh[0] < 18) then ["inside meeting window", "clear of deep-work block"] else ["clear of deep-work block"] end)
    }
    end
' "${_cal}" | jq -s --argjson max "${_max}" 'sort_by(-.fit_score) | .[0:$max]')"

cat <<JSON
{
  "schema": "slot",
  "event_type": "${_event}",
  "contact": "${_alias}",
  "tz_label": "${_tz_label}",
  "timezone": "${_tz}",
  "proposed": ${_proposed}
}
JSON
