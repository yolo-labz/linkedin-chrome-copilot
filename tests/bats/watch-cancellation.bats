#!/usr/bin/env bats
# watch-cancellation.bats — T045 cancellation triggers reschedule-pending.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "English cancellation message triggers reschedule-pending" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash -c "printf 'Hey, I need to reschedule our call on Friday.' | bash $REPO/skills/watch-cancellation/run.sh --alias contact-c3 --slot slot-002"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"state":"reschedule-pending"'* ]]
  [[ "$output" == *'"hot_queue":true'* ]]
}

@test "Portuguese cancellation triggers reschedule-pending" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash -c "printf 'Preciso remarcar a call.' | bash $REPO/skills/watch-cancellation/run.sh --alias contact-c3 --slot slot-002"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"state":"reschedule-pending"'* ]]
}

@test "non-cancellation message returns confirmed" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash -c "printf 'Looking forward to it.' | bash $REPO/skills/watch-cancellation/run.sh --alias contact-c3 --slot slot-002"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"state":"confirmed"'* ]]
  [[ "$output" == *'"hot_queue":false'* ]]
}
