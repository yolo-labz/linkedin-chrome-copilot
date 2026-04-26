#!/usr/bin/env bash
# clipboard-handoff runner. Stdin = body to copy. Args = profile + URL pattern.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"
# shellcheck source=/dev/null
. "${_self}/tools/chrome-shim.sh"

_profile=""
_url=""
_alias=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      _profile="$2"
      shift 2
      ;;
    --url)
      _url="$2"
      shift 2
      ;;
    --alias)
      _alias="$2"
      shift 2
      ;;
    *)
      printf 'clipboard-handoff: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${_profile}" ] || [ -z "${_url}" ]; then
  printf 'clipboard-handoff: usage: run.sh --profile <name> --url <pattern> [--alias <contact-XX>]\n' >&2
  exit 2
fi

if ! command -v pbcopy >/dev/null 2>&1; then
  printf 'clipboard-handoff: pbcopy not on PATH — this skill is macOS-only.\n' >&2
  exit 2
fi

# Stream stdin → clipboard.
pbcopy

# Resolve and focus the target tab.
_fp="$(lc_fingerprint "${_profile}" "${_url}" || true)"
if [ -z "${_fp}" ]; then
  printf 'clipboard-handoff: no tab matching %s in profile %s. Open it first.\n' "${_url}" "${_profile}" >&2
  exit 5
fi
lc_focus_tab "${_fp}"

# Emit PipelineEvent.
_ts="$(date +%Y-%m-%dT%H:%M:%S%z | sed -E 's/([0-9]{2})$/:\1/')"
cat <<JSON
{"schema":"pipeline-event","event":"clipboard-handoff","alias":"${_alias}","profile":"${_profile}","url":"${_url}","fingerprint":"${_fp}","ts":"${_ts}"}
JSON
