#!/usr/bin/env bats
# profile-sync.bats — T053 two tabs opened with correct locale URLs.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "emits two opened tabs, one per locale" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/profile-sync/run.sh" --profile LinkedIn --section headline
  [ "$status" -eq 0 ]
  count=$(printf '%s' "$output" | jq '.opened | length')
  [ "$count" -eq 2 ]
}

@test "both locales present (en-US + pt-BR)" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/profile-sync/run.sh" --profile LinkedIn --section headline
  [ "$status" -eq 0 ]
  locales=$(printf '%s' "$output" | jq -r '.opened[].locale' | sort | tr '\n' ' ')
  [[ "$locales" == *"en-US"* ]]
  [[ "$locales" == *"pt-BR"* ]]
}

@test "URLs carry the configured section" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/profile-sync/run.sh" --profile LinkedIn --section about
  [ "$status" -eq 0 ]
  urls=$(printf '%s' "$output" | jq -r '.opened[].url')
  [[ "$urls" == *"/edit/about/"* ]]
}
