#!/usr/bin/env bats
# draft-reply.bats — T033 register enforcement.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  FIX="$REPO/fixtures/contacts.example.json"
}

@test "linkedin DM draft ≤ 400 chars" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/draft-reply/run.sh" --alias contact-b2 --channel linkedin --contacts "$FIX"
  [ "$status" -eq 0 ]
  body_chars=$(printf '%s' "$output" | jq -r '.body_chars')
  [ "$body_chars" -le 400 ]
  [[ "$output" == *'"channel": "linkedin"'* ]]
  [[ "$output" == *'"state": "pending"'* ]]
}

@test "email draft produces subject + body" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/draft-reply/run.sh" --alias contact-g4 --channel email --contacts "$FIX"
  [ "$status" -eq 0 ]
  body=$(printf '%s' "$output" | jq -r '.body')
  [[ "$body" == *"Subject:"* ]]
}

@test "whatsapp defaults to pt-BR for pt-BR locale contact" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/draft-reply/run.sh" --alias contact-c3 --channel whatsapp --contacts "$FIX"
  [ "$status" -eq 0 ]
  body=$(printf '%s' "$output" | jq -r '.body')
  [[ "$body" == *"Oi"* ]]
}

@test "ats channel is refused" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/draft-reply/run.sh" --alias contact-j0 --channel ats --contacts "$FIX"
  [ "$status" -eq 3 ]
}
