#!/usr/bin/env bats
# guardrails.bats — T065 verdict invariants.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "deny: 10:00 slot inside morning deep-work block" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action book_slot --slot-hhmm 10:00
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "deny"'* ]]
  [[ "$output" == *'no_morning_meetings'* ]]
}

@test "allow: 15:00 slot outside morning block" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action book_slot --slot-hhmm 15:00
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "allow"'* ]]
}

@test "deny: fit_score 60 under hell-yes threshold 80" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action progress_pipeline --fit-score 60
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "deny"'* ]]
  [[ "$output" == *'hell_yes_threshold'* ]]
}

@test "deny: send without verify marker" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action send --approved
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "deny"'* ]]
  [[ "$output" == *'send_verify_required'* ]]
}

@test "deny: send without --approved" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action send --has-verify
  [ "$status" -eq 0 ]
  [[ "$output" == *'no_autosend'* ]]
}

@test "allow: send with --approved + --has-verify" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/guardrails/run.sh" --action send --approved --has-verify
  [ "$status" -eq 0 ]
  [[ "$output" == *'"verdict": "allow"'* ]]
}
