#!/usr/bin/env bats
# fuzz-pii-scan.bats — seeded property-style fuzz over pii-scan regexes.
# Minimal, deterministic, runs in CI. Replays a fixed corpus + a tiny
# pseudorandom generator so the suite is reproducible.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TMP="$(mktemp -d)"
  SEED=1337
}

teardown() {
  rm -rf "${TMP}"
}

_mktest() {
  printf '%s\n' "$1" > "${TMP}/sample.txt"
}

@test "detects obvious gmail.com email" {
  _mktest 'Contact: realuser@gmail.com'
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "allows example.invalid" {
  _mktest 'Contact: contact-a1@example.invalid'
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -eq 0 ]
}

@test "detects real-looking phone" {
  _mktest 'Phone: +55 81 99912-3456'
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "allows synthetic zero-phone" {
  _mktest 'Phone: +00-000-000-0000'
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -eq 0 ]
}

@test "detects Calendly event URL" {
  _mktest 'Book: https://calendly.com/realoperator/intro-chat'
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "fuzz: 10 mutated emails all flagged" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    _mktest "leak${i}@mail${i}.com"
    run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
    [ "$status" -ne 0 ]
  done
}

@test "fuzz: 10 synthetic emails all pass" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    _mktest "contact-${i}@example.invalid"
    run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
    [ "$status" -eq 0 ]
  done
}
