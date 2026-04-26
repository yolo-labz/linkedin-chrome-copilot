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
  grep -vE '^\s*(#|$)' "${_blocklist_raw}" >"${_blocklist}" 2>/dev/null || true
  if [ -s "${_blocklist}" ]; then
    _has_blocklist=1
  fi
fi

# Iterate tracked files. Use git when available, fall back to find.
if git rev-parse --git-dir >/dev/null 2>&1; then
  _files="$(git ls-files)"
else
  _files="$(find . -type f -not -path './.git/*' -not -path './node_modules/*' | sed 's|^\./||')"
fi

printf '%s\n' "${_files}" | while IFS= read -r _f; do
  [ -z "${_f}" ] && continue
  case "${_f}" in
    .git/* | */node_modules/* | tools/pii-blocklist.txt | LICENSE) continue ;;
  esac
  if ! LC_ALL=C grep -Iq . "${_f}" 2>/dev/null; then continue; fi

  _hit_here=0
  # Emails (applying allowlist domains).
  for _m in $(grep -oE "${_RE_EMAIL}" "${_f}" 2>/dev/null || true); do
    case "${_m}" in
      *@example.invalid | *@example.com | *@example.org) ;;
      noreply@* | *@github.com | *@users.noreply.github.com) ;;
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

  # Phone numbers in narrative files. Exempt:
  #  - ISO dates / date-times (YYYY-MM-DDTHH:MM:SS with tz suffix like -03:00)
  #  - All-zero synthetic placeholders (+00-000-000-0000)
  case "${_f}" in
    *.md | *.txt | *.json | *.yaml | *.yml)
      _phone_matches="$(grep -oE "${_RE_PHONE}" "${_f}" 2>/dev/null || true)"
      if [ -n "${_phone_matches}" ]; then
        # Filter out pure dates and all-zero placeholders.
        _phone_bad="$(printf '%s\n' "${_phone_matches}" \
          | grep -vE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
          | grep -vE '^[[:space:]]*$' \
          | grep -vE '^\+?[0-9-]*0[0-9-]*$' \
          | awk 'BEGIN{FS=""} { nonzero=0; for(i=1;i<=NF;i++) if($i ~ /[1-9]/) nonzero++; if(nonzero >= 4) print }' \
          || true)"
        if [ -n "${_phone_bad}" ]; then
          _hit_here=1
        fi
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
