#!/usr/bin/env bash
# fixtures-validate.sh — ensure every JSON fixture satisfies its schema.
#
# Uses `jq` (already a runtime dep) for shape + required-field checks.
# Full JSON Schema validation is out-of-scope for this smoke test — CI adds a
# `ajv-cli` run in ci.yml for draft-07 conformance.
#
# Exit codes:
#   0  all fixtures pass structural smoke tests
#   1  at least one fixture failed

set -eu

_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${_root}"

_fail=0

_check_json() {
  _file="$1"
  _desc="$2"
  if [ ! -f "${_file}" ]; then
    printf 'fixtures-validate: skip (missing) %s\n' "${_file}"
    return 0
  fi
  if ! jq -e . "${_file}" >/dev/null 2>&1; then
    printf 'fixtures-validate: FAIL parse %s (%s)\n' "${_file}" "${_desc}" >&2
    _fail=1
    return 1
  fi
  printf 'fixtures-validate: PASS parse %s\n' "${_file}"
}

_check_required() {
  _file="$1"
  _field="$2"
  if ! jq -e "${_field}" "${_file}" >/dev/null 2>&1; then
    printf 'fixtures-validate: FAIL field %s missing from %s\n' "${_field}" "${_file}" >&2
    _fail=1
    return 1
  fi
  return 0
}

# aliases.example.json
if [ -f fixtures/aliases.example.json ]; then
  _check_json fixtures/aliases.example.json "alias map"
  _check_required fixtures/aliases.example.json '.version'
  _check_required fixtures/aliases.example.json '.contacts'
fi

# contacts.example.json
if [ -f fixtures/contacts.example.json ]; then
  _check_json fixtures/contacts.example.json "contacts fixture"
  _check_required fixtures/contacts.example.json '.[0].alias'
  _check_required fixtures/contacts.example.json '.[0].channel'
  _check_required fixtures/contacts.example.json '.[0].stage'
fi

# free-window.example.json
if [ -f fixtures/free-window.example.json ]; then
  _check_json fixtures/free-window.example.json "free-window"
  _check_required fixtures/free-window.example.json '.timezone'
fi

# calendly-response.example.json
if [ -f fixtures/calendly-response.example.json ]; then
  _check_json fixtures/calendly-response.example.json "calendly response"
fi

# engineering-keywords.json
if [ -f fixtures/engineering-keywords.json ]; then
  _check_json fixtures/engineering-keywords.json "engineering keywords"
fi

# Schemas themselves should parse as JSON.
for _s in schemas/*.schema.json; do
  [ -f "${_s}" ] || continue
  _check_json "${_s}" "schema"
  _check_required "${_s}" '."$schema"'
done

if [ "${_fail}" -ne 0 ]; then
  printf '\nfixtures-validate: one or more fixtures failed.\n' >&2
  exit 1
fi

printf '\nfixtures-validate: all fixtures pass structural smoke tests.\n'
exit 0
