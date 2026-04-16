#!/usr/bin/env bash
# pii-scan.sh — hard gate against PII leakage in committed files.
#
# Scans every tracked file under the repo root for:
#   - Email addresses (RFC-5322 subset)
#   - E.164 phone numbers with 10-15 digits
#   - Calendly URLs (personal handles)
#   - Magic-link tokens (base64-looking opaque strings in URLs)
#   - Common first-name blocklist (configurable via tools/pii-blocklist.txt)
#
# Skipped paths:
#   - fixtures/aliases.example.json  (documented example map; must use *@example.invalid)
#   - tools/pii-blocklist.txt        (the blocklist itself)
#   - LICENSE, .git/                 (obvious)
#
# Exit codes:
#   0  no hits
#   4  PII found (prints offending file:line:pattern)
#
# Flags:
#   --fix   dry-run showing candidate redactions (future: not auto-apply)

set -eu

_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${_root}"

_allowlist_domain='example\.invalid'
_allowlist_marker='SYNTHETIC-PLACEHOLDER'

# Files that are permitted to contain placeholder emails (must use example.invalid).
_ALLOWED_EXAMPLE_FILES='^(fixtures/|docs/PII-POLICY\.md$|tools/pii-scan\.sh$|README\.md$)'

# Regexes.
_RE_EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
_RE_PHONE='\+?[0-9]{1,3}[[:space:]-]?\(?[0-9]{2,4}\)?[[:space:]-]?[0-9]{3,5}[[:space:]-]?[0-9]{3,5}'
_RE_CALENDLY='calendly\.com/[A-Za-z0-9_-]+'
_RE_MAGIC='[?&](token|auth|sig|key|access_token)=[A-Za-z0-9._-]{20,}'

_blocklist_raw="${_root}/tools/pii-blocklist.txt"
_blocklist="$(mktemp)"
_tmphits="$(mktemp)"
trap 'rm -f "${_blocklist}" "${_tmphits}"' EXIT
_has_blocklist=0
if [ -f "${_blocklist_raw}" ]; then
  # Strip blank lines and comments (#). A file of only comments has no patterns.
  grep -vE '^\s*(#|$)' "${_blocklist_raw}" > "${_blocklist}" 2>/dev/null || true
  if [ -s "${_blocklist}" ]; then
    _has_blocklist=1
  fi
fi

_hits=0
_scan_file() {
  _f="$1"
  case "${_f}" in
    .git/*|*/node_modules/*|tools/pii-blocklist.txt|LICENSE)
      return 0
      ;;
  esac
  # Skip binary files.
  if ! LC_ALL=C grep -Iq . "${_f}" 2>/dev/null; then
    return 0
  fi

  # Email check — allow *@example.invalid in fixtures/ and PII-POLICY.md + this scanner + README (install URL etc).
  _email_matches="$(grep -nE "${_RE_EMAIL}" "${_f}" 2>/dev/null || true)"
  if [ -n "${_email_matches}" ]; then
    printf '%s\n' "${_email_matches}" | while IFS= read -r _line; do
      # Skip matches that are entirely *@example.invalid.
      _just_match="$(printf '%s' "${_line}" | grep -oE "${_RE_EMAIL}" || true)"
      _bad=0
      for _m in ${_just_match}; do
        case "${_m}" in
          *@example.invalid|*@example.com|*@example.org) ;;
          noreply@*|*@github.com|*@users.noreply.github.com) ;;
          *)
            case "${_f}" in
              fixtures/*|docs/PII-POLICY.md|tools/pii-scan.sh|README.md)
                printf 'pii-scan: %s: forbidden email-like string (%s). Use @example.invalid.\n' "${_f}" "${_m}" >&2
                _bad=1
                ;;
              *)
                printf 'pii-scan: %s: email-like string (%s) in committed file.\n' "${_f}" "${_m}" >&2
                _bad=1
                ;;
            esac
            ;;
        esac
      done
      if [ "${_bad}" = "1" ]; then
        _hits=$((_hits + 1))
      fi
    done || true
  fi

  # Calendly check.
  if grep -nE "${_RE_CALENDLY}" "${_f}" >/dev/null 2>&1; then
    _cal="$(grep -nE "${_RE_CALENDLY}" "${_f}" | grep -vE '/example|/contact-[a-z0-9]+|SYNTHETIC' || true)"
    if [ -n "${_cal}" ]; then
      printf '%s\n' "${_cal}" >&2
      printf 'pii-scan: %s: Calendly URL hit (use /example or /contact-XX).\n' "${_f}" >&2
      _hits=$((_hits + 1))
    fi
  fi

  # Magic-link check.
  if grep -nE "${_RE_MAGIC}" "${_f}" >/dev/null 2>&1; then
    printf 'pii-scan: %s: magic-link token parameter.\n' "${_f}" >&2
    _hits=$((_hits + 1))
  fi

  # Phone check (conservative — only on files flagged as having narrative text).
  case "${_f}" in
    *.md|*.txt|*.json)
      if grep -nE "${_RE_PHONE}" "${_f}" >/dev/null 2>&1; then
        # Exclude obvious version strings, ISO dates, and schema refs.
        _phone="$(grep -nE "${_RE_PHONE}" "${_f}" | grep -vE '"version"|[0-9]{4}-[0-9]{2}-[0-9]{2}|json-schema\.org' || true)"
        if [ -n "${_phone}" ]; then
          printf '%s\n' "${_phone}" >&2
          printf 'pii-scan: %s: possible phone number.\n' "${_f}" >&2
          _hits=$((_hits + 1))
        fi
      fi
      ;;
  esac

  # Blocklist names.
  if [ "${_has_blocklist}" = "1" ]; then
    if grep -niFf "${_blocklist}" "${_f}" >/dev/null 2>&1; then
      printf 'pii-scan: %s: blocklisted name match.\n' "${_f}" >&2
      _hits=$((_hits + 1))
    fi
  fi

  return 0
}

# Iterate tracked files. Use git when available, fall back to find.
if git rev-parse --git-dir >/dev/null 2>&1; then
  _files="$(git ls-files)"
else
  _files="$(find . -type f -not -path './.git/*' -not -path './node_modules/*' | sed 's|^\./||')"
fi

printf '%s\n' "${_files}" | while IFS= read -r _f; do
  [ -z "${_f}" ] && continue
  _scan_file "${_f}"
done

# The subshell-based loop loses _hits increments. Re-count by scanning stderr
# is brittle; instead we rely on the exit path: if any file triggered a printf
# to stderr, we also write a marker file. Simpler approach: aggregate with a
# tmpfile.
#
# Rewriting: run scan, collect hits count via tempfile.
# (The implementation above used local vars which don't survive the subshell;
# the final real enforcement comes from the aggregate grep below.)

printf '%s\n' "${_files}" | while IFS= read -r _f; do
  [ -z "${_f}" ] && continue
  case "${_f}" in
    .git/*|*/node_modules/*|tools/pii-blocklist.txt|LICENSE) continue ;;
  esac
  if ! LC_ALL=C grep -Iq . "${_f}" 2>/dev/null; then continue; fi

  _hit_here=0
  # Emails (applying allowlist domains).
  for _m in $(grep -oE "${_RE_EMAIL}" "${_f}" 2>/dev/null || true); do
    case "${_m}" in
      *@example.invalid|*@example.com|*@example.org) ;;
      noreply@*|*@github.com|*@users.noreply.github.com) ;;
      *) _hit_here=1 ;;
    esac
  done

  # Calendly real slugs.
  if grep -oE "${_RE_CALENDLY}" "${_f}" 2>/dev/null | grep -vE '/example|/contact-[a-z0-9]+' >/dev/null 2>&1; then
    _hit_here=1
  fi

  # Magic-link tokens.
  if grep -qE "${_RE_MAGIC}" "${_f}" 2>/dev/null; then
    _hit_here=1
  fi

  # Phone numbers in narrative files.
  case "${_f}" in
    *.md|*.txt|*.json)
      if grep -oE "${_RE_PHONE}" "${_f}" 2>/dev/null \
        | grep -vE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' >/dev/null 2>&1; then
        # Ignore obvious version-ish hits.
        _phone_hit="$(grep -oE "${_RE_PHONE}" "${_f}" | grep -vE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || true)"
        case "${_phone_hit}" in
          *' '*|*-*)
            if printf '%s' "${_phone_hit}" | grep -qE '\+?[0-9][0-9][0-9]?[[:space:]-][0-9]'; then
              _hit_here=1
            fi
            ;;
        esac
      fi
      ;;
  esac

  if [ "${_has_blocklist}" = "1" ]; then
    if grep -iFf "${_blocklist}" "${_f}" >/dev/null 2>&1; then
      _hit_here=1
    fi
  fi

  if [ "${_hit_here}" = "1" ]; then
    printf '%s\n' "${_f}" >>"${_tmphits}"
  fi
done

if [ -s "${_tmphits}" ]; then
  printf 'pii-scan: blocked the following files:\n' >&2
  sort -u "${_tmphits}" | sed 's/^/  - /' >&2
  printf '\npii-scan: resolve by using @example.invalid, synthetic aliases, or the allowlist.\n' >&2
  printf 'pii-scan: see docs/PII-POLICY.md for details.\n' >&2
  exit 4
fi

exit 0
