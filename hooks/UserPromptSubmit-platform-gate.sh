#!/usr/bin/env bash
# UserPromptSubmit-platform-gate.sh — refuse work on non-macOS before any skill
# runs. Belt-and-braces: every skill also sources platform-gate.sh.

set -eu

_plugin_root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
# shellcheck source=/dev/null
. "${_plugin_root}/tools/platform-gate.sh"
