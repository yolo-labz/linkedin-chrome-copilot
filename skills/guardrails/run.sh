#!/usr/bin/env bash
# guardrails runner. Pure-bash YAML subset parser (key: value).

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_cfg="${LC_GUARDRAILS_PATH:-${_self}/config/guardrails.yaml}"
_action=""
_slot_hhmm=""
_fit_score=""
_channel=""
_approved=0
_has_verify=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --action)
      _action="$2"
      shift 2
      ;;
    --slot-hhmm)
      _slot_hhmm="$2"
      shift 2
      ;;
    --fit-score)
      _fit_score="$2"
      shift 2
      ;;
    --channel)
      _channel="$2"
      shift 2
      ;;
    --approved)
      _approved=1
      shift
      ;;
    --has-verify)
      _has_verify=1
      shift
      ;;
    *)
      printf 'guardrails: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${_action}" ]; then
  printf 'guardrails: --action required\n' >&2
  exit 2
fi
if [ ! -f "${_cfg}" ]; then
  printf 'guardrails: config missing: %s\n' "${_cfg}" >&2
  exit 4
fi

# Extract a scalar field nested under a rule key (awk state machine).
_get() {
  _rule="$1"
  _field="$2"
  awk -v r="${_rule}" -v f="${_field}" '
    BEGIN { in_r=0 }
    $0 ~ "^  " r ":" { in_r=1; next }
    in_r && /^  [a-z_]+:/ { in_r=0 }
    in_r && $0 ~ ("^    " f ":") {
      sub("^    " f ": *", "")
      gsub(/^[[:space:]]*"|"[[:space:]]*$/, "")
      print; exit
    }
  ' "${_cfg}"
}

_hhmm_to_min() {
  IFS=: read -r _h _m <<EOF
$1
EOF
  printf '%s' $((10#${_h} * 60 + 10#${_m}))
}

_triggered=""
_verdict="allow"
_sep=""

_add() {
  _rule="$1"
  _reason="$2"
  _triggered="${_triggered}${_sep}{\"rule\":\"${_rule}\",\"reason\":\"${_reason}\"}"
  _sep=","
}

# Rule 1: no_morning_meetings — only if action=book_slot + slot_hhmm present.
if [ "${_action}" = "book_slot" ] && [ -n "${_slot_hhmm}" ]; then
  _en="$(_get no_morning_meetings enabled)"
  if [ "${_en}" = "true" ]; then
    _st="$(_get no_morning_meetings start)"
    _et="$(_get no_morning_meetings end)"
    _slot_min="$(_hhmm_to_min "${_slot_hhmm}")"
    _st_min="$(_hhmm_to_min "${_st}")"
    _et_min="$(_hhmm_to_min "${_et}")"
    if [ "${_slot_min}" -ge "${_st_min}" ] && [ "${_slot_min}" -lt "${_et_min}" ]; then
      _add "no_morning_meetings" "slot ${_slot_hhmm} inside ${_st}-${_et} deep-work block"
      _verdict="deny"
    fi
  fi
fi

# Rule 2: hell_yes_threshold — only on progress_pipeline + fit_score numeric.
if [ "${_action}" = "progress_pipeline" ] && [ -n "${_fit_score}" ]; then
  _en="$(_get hell_yes_threshold enabled)"
  if [ "${_en}" = "true" ]; then
    _score="$(_get hell_yes_threshold score)"
    if [ "${_fit_score}" -lt "${_score}" ]; then
      _add "hell_yes_threshold" "fit_score ${_fit_score} below threshold ${_score}"
      _verdict="deny"
    fi
  fi
fi

# Rule 3: send_verify_required — any action=send must carry --has-verify.
if [ "${_action}" = "send" ]; then
  _en="$(_get send_verify_required enabled)"
  if [ "${_en}" = "true" ] && [ "${_has_verify}" -eq 0 ]; then
    _add "send_verify_required" "DOM re-read verification not attached to Draft"
    _verdict="deny"
  fi
  _en2="$(_get no_autosend enabled)"
  if [ "${_en2}" = "true" ] && [ "${_approved}" -eq 0 ]; then
    _add "no_autosend" "operator approval (--approved) required before send"
    _verdict="deny"
  fi
fi

# Rule 4: async_over_live — warning only when booking for a channel that prefers async.
if [ "${_action}" = "book_slot" ] && [ -n "${_channel}" ]; then
  _en="$(_get async_over_live enabled)"
  if [ "${_en}" = "true" ]; then
    case "${_channel}" in
      linkedin | email | whatsapp)
        _add "async_over_live" "channel ${_channel} typically resolvable async — consider drafting first"
        if [ "${_verdict}" = "allow" ]; then _verdict="warn"; fi
        ;;
    esac
  fi
fi

cat <<JSON
{
  "schema": "guardrails-verdict",
  "action": "${_action}",
  "verdict": "${_verdict}",
  "triggered": [${_triggered}]
}
JSON
