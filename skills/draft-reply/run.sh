#!/usr/bin/env bash
# draft-reply runner.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_alias=""
_channel=""
_contacts="${LC_CONTACTS_PATH:-${_self}/fixtures/contacts.example.json}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --alias)
      _alias="$2"
      shift 2
      ;;
    --channel)
      _channel="$2"
      shift 2
      ;;
    --contacts)
      _contacts="$2"
      shift 2
      ;;
    *)
      printf 'draft-reply: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${_alias}" ] || [ -z "${_channel}" ]; then
  printf 'draft-reply: usage: run.sh --alias <contact-XX> --channel <linkedin|email|whatsapp|ats|github>\n' >&2
  exit 2
fi

if [ "${_channel}" = "ats" ]; then
  printf 'draft-reply: ATS channel is auto-form only. Fill the ATS application form directly.\n' >&2
  exit 3
fi

# Lookup contact.
_contact_json="$(jq --arg a "${_alias}" '[.[] | select(.alias==$a)] | first' "${_contacts}")"
if [ -z "${_contact_json}" ] || [ "${_contact_json}" = "null" ]; then
  printf 'draft-reply: alias %s not found in %s\n' "${_alias}" "${_contacts}" >&2
  exit 4
fi

_org_slug="$(printf '%s' "${_contact_json}" | jq -r '.org_slug')"
_role="$(printf '%s' "${_contact_json}" | jq -r '.role_label')"
_locale="$(printf '%s' "${_contact_json}" | jq -r '.locale // "en-US"')"

# WhatsApp + pt-BR default.
if [ "${_channel}" = "whatsapp" ] && [ "${_locale}" = "en-US" ]; then
  # Only override if operator has not explicitly set English; default is pt-BR.
  :
fi

# Compose the body per channel. Deliberately generic — real copy is operator-
# supplied; this is a synthesis stub that the agent wraps.
case "${_channel}" in
  linkedin)
    _body="Hi ${_alias}, thanks for the note about the ${_role} role at ${_org_slug}. Happy to chat — what works this week? —Pedro"
    _max=400
    ;;
  email)
    _body="Subject: Re: ${_role} at ${_org_slug}\n\nHi ${_alias},\n\nThanks for reaching out about the ${_role} opportunity. I'd be glad to discuss. Could we find a time this week?\n\nBest,\nPedro"
    _max=1500
    ;;
  whatsapp)
    if [ "${_locale}" = "pt-BR" ]; then
      _body="Oi ${_alias}! Obrigado pelo contato sobre ${_role} na ${_org_slug}. Podemos marcar algo esta semana?"
    else
      _body="Hey ${_alias}! Thanks for the note about ${_role} at ${_org_slug}. Free to chat this week?"
    fi
    _max=600
    ;;
  github)
    _body="Thanks for the ping — following up on the ${_role} role at ${_org_slug}."
    _max=1000
    ;;
  *)
    printf 'draft-reply: unsupported channel %s\n' "${_channel}" >&2
    exit 2
    ;;
esac

_len="${#_body}"
if [ "${_len}" -gt "${_max}" ]; then
  _body="$(printf '%s' "${_body}" | cut -c1-"${_max}")"
  _len="${_max}"
fi

# Access method: prefer direct. If chrome-shim probe fails, switch to clipboard-only.
_access="direct"
if ! command -v pbcopy >/dev/null 2>&1; then
  _access="clipboard-only"
fi
if [ -n "${LC_FORCE_CLIPBOARD_ONLY:-}" ]; then
  _access="clipboard-only"
fi

_ts="$(date +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')"
cat <<JSON
{
  "schema": "draft",
  "alias": "${_alias}",
  "channel": "${_channel}",
  "locale": "${_locale}",
  "state": "pending",
  "access_method": "${_access}",
  "body_chars": ${_len},
  "max_chars": ${_max},
  "created": "${_ts}",
  "body": $(printf '%s' "${_body}" | jq -Rs .)
}
JSON
