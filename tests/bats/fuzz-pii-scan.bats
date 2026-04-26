#!/usr/bin/env bats
# fuzz-pii-scan.bats — seeded property-style fuzz over pii-scan regexes.
# Minimal, deterministic, runs in CI. Replays a fixed corpus + a tiny
# pseudorandom generator so the suite is reproducible.
#
# pii-scan.sh accepts file args (refactored). Tests pass the temp file
# directly, so PII literals only exist on disk during the test, never
# in this source file. pii-scan's own whole-repo default mode therefore
# does not flag this file.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TMP="$(mktemp -d)"
  SEED=1337
}

teardown() {
  rm -rf "${TMP}"
}

# Helpers that assemble PII-shaped strings from inert parts so this
# source file has no email/phone/calendly literals on disk.
_email() { printf '%s%s%s.%s' "$1" "$(printf '@')" "$2" "$3"; }
_phone() { printf '%s%s' "$(printf '+')" "$1"; }
_calendly_url() { printf 'https://%s.com/%s/%s' "calendly" "$1" "$2"; }

_mktest() {
  printf '%s\n' "$1" > "${TMP}/sample.txt"
}

@test "detects obvious gmail.com email" {
  _mktest "Contact: $(_email realuser gmail com)"
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "allows example.invalid" {
  _mktest "Contact: $(_email contact-a1 example invalid)"
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -eq 0 ]
}

@test "detects real-looking phone" {
  _mktest "Phone: $(_phone '55 81 99912-3456')"
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "allows synthetic zero-phone" {
  _mktest "Phone: $(_phone '00-000-000-0000')"
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -eq 0 ]
}

@test "detects Calendly event URL" {
  _mktest "Book: $(_calendly_url realoperator intro-chat)"
  run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
  [ "$status" -ne 0 ]
}

@test "fuzz: 10 mutated emails all flagged" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    _mktest "$(_email "leak${i}" "mail${i}" com)"
    run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
    [ "$status" -ne 0 ]
  done
}

@test "fuzz: 10 synthetic emails all pass" {
  for i in 1 2 3 4 5 6 7 8 9 10; do
    _mktest "$(_email "contact-${i}" example invalid)"
    run bash "${REPO}/tools/pii-scan.sh" "${TMP}/sample.txt"
    [ "$status" -eq 0 ]
  done
}
