#!/usr/bin/env bats
# tailor-cv.bats — T052 filename pattern, coverage threshold, no bullet loss.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TMP="$(mktemp -d)"
}

teardown() {
  rm -rf "${TMP}"
}

@test "emits CVVariant JSON with org/role slugs" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/tailor-cv/run.sh" \
    --jd "$REPO/fixtures/job-description.example.md" \
    --out-dir "${TMP}"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"org_slug": "acme-corp"'* ]]
  [[ "$output" == *'"role_slug": "staff-backend-engineer"'* ]]
}

@test "output filename follows cv-{org}-{role}-{YYYYMMDD}.md pattern" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/tailor-cv/run.sh" \
    --jd "$REPO/fixtures/job-description.example.md" \
    --out-dir "${TMP}"
  [ "$status" -eq 0 ]
  path=$(printf '%s' "$output" | jq -r '.output_md_path')
  [[ "$(basename "$path")" =~ ^cv-acme-corp-staff-backend-engineer-[0-9]{8}\.md$ ]]
  [ -f "$path" ]
}

@test "keyword coverage >= 80 on synthetic fixture pair" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  run bash "$REPO/skills/tailor-cv/run.sh" \
    --jd "$REPO/fixtures/job-description.example.md" \
    --out-dir "${TMP}"
  [ "$status" -eq 0 ]
  pct=$(printf '%s' "$output" | jq '.keyword_coverage_pct')
  [ "$pct" -ge 80 ]
}

@test "reordered CV preserves bullet count (no hallucination, no loss)" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  base_bullets=$(grep -c '^- ' "$REPO/fixtures/cv-base.example.md" || true)
  run bash "$REPO/skills/tailor-cv/run.sh" \
    --jd "$REPO/fixtures/job-description.example.md" \
    --out-dir "${TMP}"
  [ "$status" -eq 0 ]
  path=$(printf '%s' "$output" | jq -r '.output_md_path')
  out_bullets=$(grep -c '^- ' "$path" || true)
  [ "$base_bullets" -eq "$out_bullets" ]
}
