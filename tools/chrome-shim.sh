#!/usr/bin/env bash
# chrome-shim.sh — thin wrapper over claude-mac-chrome's chrome-lib.sh.
#
# Re-exposes the subset of chrome-lib functions this plugin needs. All browser
# I/O in this repo goes through these wrappers. No raw AppleScript lives here.
#
# Requires: platform-gate.sh to have sourced first (sets LC_SIBLING_ROOT).
# Exit codes:
#   0  OK
#   5  chrome-lib.sh missing
#   6  unnamed profile (catalog lookup required)

set -eu

if [ -z "${LC_SIBLING_ROOT:-}" ]; then
  # shellcheck source=/dev/null
  . "$(dirname "${BASH_SOURCE[0]}")/platform-gate.sh"
fi

# claude-mac-chrome layout (post-1.1.x): chrome-lib lives under skills/
# rather than the legacy lib/. Probe both for backward compatibility.
for _candidate in \
  "${LC_SIBLING_ROOT}/skills/chrome-multi-profile/chrome-lib.sh" \
  "${LC_SIBLING_ROOT}/lib/chrome-lib.sh"; do
  if [ -f "${_candidate}" ]; then
    _chrome_lib="${_candidate}"
    break
  fi
done
if [ -z "${_chrome_lib:-}" ]; then
  printf 'chrome-shim: chrome-lib.sh not found under %s/skills/chrome-multi-profile/ or /lib/\n' "${LC_SIBLING_ROOT}" >&2
  exit 5
fi

# shellcheck source=/dev/null
. "${_chrome_lib}"

# --- Wrappers ---

# catalog — emit JSON of { profiles: [...], windows: [...], tabs: [...] }.
lc_catalog() {
  chrome_catalog "$@"
}

# fingerprint — stable ID for a tab given URL pattern + profile name.
lc_fingerprint() {
  if [ "$#" -lt 2 ]; then
    printf 'lc_fingerprint: usage: <profile-name> <url-pattern>\n' >&2
    return 6
  fi
  chrome_fingerprint "$1" "$2"
}

# window_for — resolve a profile name to its window ID.
lc_window_for() {
  if [ -z "${1:-}" ]; then
    printf 'lc_window_for: profile name required (no unnamed profiles)\n' >&2
    return 6
  fi
  chrome_window_for "$1"
}

# execute_js — run a JS snippet in a tab, return stdout.
lc_execute_js() {
  chrome_execute_js "$@"
}

# focus_tab — raise a tab identified by fingerprint.
lc_focus_tab() {
  chrome_focus_tab "$@"
}

# check_inboxes — emit unread counts per configured inbox tab.
lc_check_inboxes() {
  chrome_check_inboxes "$@"
}

# open_tab — open a URL in a specific profile, return new tab fingerprint.
lc_open_tab() {
  if [ "$#" -lt 2 ]; then
    printf 'lc_open_tab: usage: <profile-name> <url>\n' >&2
    return 6
  fi
  chrome_open_tab "$1" "$2"
}
