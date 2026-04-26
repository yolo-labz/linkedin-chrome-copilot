#!/usr/bin/env bash
# platform-gate.sh — refuse non-Darwin; verify sibling plugin present.
#
# Contract: every skill sources this as its first non-comment line.
# Exit codes:
#   0  OK (macOS + sibling plugin present)
#   2  non-macOS platform
#   3  sibling plugin missing or wrong version
#
# macOS 13+ baseline — bash 3.2 compatible (no declare -A, no mapfile).

set -eu
# Note: pipefail unavailable in bash 3.2 under strict POSIX. Skip.

_plat_os="$(uname -s)"
if [ "${_plat_os}" != "Darwin" ]; then
  printf 'linkedin-chrome-copilot: unsupported platform (%s).\n' "${_plat_os}" >&2
  printf '  This plugin drives Chrome via macOS AppleScript and has no Linux/Windows equivalent.\n' >&2
  printf '  Install on a macOS 13+ host.\n' >&2
  exit 2
fi

# Sibling plugin discovery. CLAUDE_PLUGIN_ROOT points at this plugin's root
# when invoked by the Claude Code runtime. Fall back to a best-effort parent
# walk if unset (e.g., during `bats` tests).
_plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
_sibling_root="${_plugin_root}/../claude-mac-chrome"

if [ ! -d "${_sibling_root}" ]; then
  printf 'linkedin-chrome-copilot: sibling plugin claude-mac-chrome not found.\n' >&2
  printf '  Expected at: %s\n' "${_sibling_root}" >&2
  printf '  Install via: claude plugins install yolo-labz/claude-mac-chrome\n' >&2
  exit 3
fi

# Version floor check — sibling plugin must be >= 1.1.1 (stable window IDs).
_sibling_manifest="${_sibling_root}/.claude-plugin/plugin.json"
if [ -f "${_sibling_manifest}" ]; then
  _sibling_ver="$(grep -E '"version"' "${_sibling_manifest}" | head -n 1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  case "${_sibling_ver}" in
    0.* | 1.0.* | 1.1.0)
      printf 'linkedin-chrome-copilot: claude-mac-chrome %s is too old (need >= 1.1.1).\n' "${_sibling_ver}" >&2
      exit 3
      ;;
  esac
fi

# Export plugin root for downstream skills.
export LC_PLUGIN_ROOT="${_plugin_root}"
export LC_SIBLING_ROOT="${_sibling_root}"
