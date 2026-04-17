#!/usr/bin/env bats
# quarterly-reset.bats — T066 archive + noop behaviors.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "${TMP}"
}

@test "noop when not on quarter boundary" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/quarterly-reset/run.sh" --archive-dir "${TMP}" --today-iso 2026-05-15
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "noop"'* ]]
}

@test "archived on 04-01 boundary" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/quarterly-reset/run.sh" --archive-dir "${TMP}" --today-iso 2026-04-01
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "archived"'* ]]
  [[ "$output" == *'Q2'* ]]
  [ -f "${TMP}/session-log-2026-Q2.md" ]
}

@test "--force archives mid-quarter" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/quarterly-reset/run.sh" --archive-dir "${TMP}" --today-iso 2026-05-15 --force
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "archived"'* ]]
}

@test "events_archived count > 0 on the example save-state" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/quarterly-reset/run.sh" --archive-dir "${TMP}" --today-iso 2026-04-01
  [ "$status" -eq 0 ]
  n=$(printf '%s' "$output" | jq '.events_archived')
  [ "$n" -gt 0 ]
}
