#!/usr/bin/env bats
# resume-session.bats — T025 happy path + error paths.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export PATH="$REPO/tools:$PATH"
  FIXTURE="$REPO/fixtures/save-state.example.md"
}

@test "happy path: 10-contact fixture emits >= 3 next actions" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "macOS-only — platform-gate refuses non-Darwin"
  fi
  run bash "$REPO/skills/resume-session/run.sh" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"schema": "save-state"'* ]]
  [[ "$output" == *'"active_contacts": 10'* ]]
  [[ "$output" == *'"hot_priorities"'* ]]
  # Count next_actions rank entries — must be >= 3.
  count=$(printf '%s' "$output" | grep -oE '"rank":[[:space:]]*[0-9]+' | wc -l | tr -d ' ')
  [ "$count" -ge 3 ]
}

@test "missing save-state offers bootstrap instructions" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "macOS-only — platform-gate refuses non-Darwin"
  fi
  run bash "$REPO/skills/resume-session/run.sh" "/does/not/exist/save-state.md"
  [ "$status" -eq 7 ]
  [[ "$output" == *"Bootstrap"* ]]
}

@test "closed contact count matches fixture" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "macOS-only"
  fi
  run bash "$REPO/skills/resume-session/run.sh" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"closed_contacts": 3'* ]]
}
