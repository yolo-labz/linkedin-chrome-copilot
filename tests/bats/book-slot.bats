#!/usr/bin/env bats
# book-slot.bats — T044 deep-work rejection + tz_label presence.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "emits ≤ 3 slots" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/book-slot/run.sh" --contact contact-c3 --source-url 'https://calendly.com/example/technical-screen'
  [ "$status" -eq 0 ]
  count=$(printf '%s' "$output" | jq '.proposed | length')
  [ "$count" -le 3 ]
}

@test "every proposed slot has tz_label" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/book-slot/run.sh" --contact contact-c3 --source-url 'https://calendly.com/example/technical-screen'
  [ "$status" -eq 0 ]
  unlabeled=$(printf '%s' "$output" | jq '[.proposed[] | select((.tz_label // "") == "")] | length')
  [ "$unlabeled" -eq 0 ]
}

@test "no slot inside deep-work block (09:00-12:00 BRT)" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/book-slot/run.sh" --contact contact-c3 --source-url 'https://calendly.com/example/technical-screen'
  [ "$status" -eq 0 ]
  # local_hhmm is HH:MM in local time; none should start in 09:00-11:59.
  bad=$(printf '%s' "$output" | jq '[.proposed[] | select(.local_hhmm >= "09:00" and .local_hhmm < "12:00")] | length')
  [ "$bad" -eq 0 ]
}
