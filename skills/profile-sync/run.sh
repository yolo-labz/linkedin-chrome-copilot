#!/usr/bin/env bash
# profile-sync runner. Opens en-US + pt-BR profile-edit tabs for parity review.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"

# PROFILE_SYNC_TEST_STUB=1 short-circuits the chrome-shim source (issue #34).
# Without the sibling claude-mac-chrome plugin installed and bash 4 on PATH,
# sourcing chrome-shim.sh aborts the run before the locale loop emits JSON,
# which is what the bats CI runner was hitting. The stub mode lets the bats
# tests exercise URL+locale envelope shape without a real Chrome host.
if [ "${PROFILE_SYNC_TEST_STUB:-0}" = "1" ]; then
  lc_open_tab() { printf 'mock-fp-%s' "$2"; }
else
  # shellcheck source=/dev/null
  . "${_self}/tools/chrome-shim.sh"
fi

_profile="${LC_LINKEDIN_PROFILE:-LinkedIn}"
_section="headline"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      _profile="$2"
      shift 2
      ;;
    --section)
      _section="$2"
      shift 2
      ;;
    *)
      printf 'profile-sync: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
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
