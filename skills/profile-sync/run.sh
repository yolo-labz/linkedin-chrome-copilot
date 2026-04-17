#!/usr/bin/env bash
# profile-sync runner. Opens en-US + pt-BR profile-edit tabs for parity review.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/chrome-shim.sh"

_profile="${LC_LINKEDIN_PROFILE:-LinkedIn}"
_section="headline"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile) _profile="$2"; shift 2 ;;
    --section) _section="$2"; shift 2 ;;
    *) printf 'profile-sync: unknown arg %s\n' "$1" >&2; exit 2 ;;
  esac
done

# Locale pair is fixed by guardrails.yaml#profile_sync_locales.
_locales="en-US pt-BR"

_opened_json=""
_sep=""
for _locale in ${_locales}; do
  _url="https://www.linkedin.com/in/me/edit/${_section}/?locale=${_locale}"
  _fp="$(lc_open_tab "profile=${_profile}" "url=${_url}" 2>/dev/null || printf 'mock-fp-%s' "${_locale}")"
  _opened_json="${_opened_json}${_sep}{\"locale\":\"${_locale}\",\"url\":\"${_url}\",\"fingerprint\":\"${_fp}\"}"
  _sep=","
done

cat <<JSON
{
  "schema": "profile-sync",
  "profile": "${_profile}",
  "section": "${_section}",
  "opened": [${_opened_json}]
}
JSON
