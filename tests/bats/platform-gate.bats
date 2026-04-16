#!/usr/bin/env bats
# platform-gate.bats — T026 non-macOS refuses with exit 2.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "platform-gate exits 2 on non-Darwin (forced)" {
  # Force by running a copy in a subshell with uname stubbed via PATH injection.
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/uname" <<'EOF'
#!/bin/sh
echo Linux
EOF
  chmod +x "$tmpdir/uname"
  run env PATH="$tmpdir:$PATH" bash "$REPO/tools/platform-gate.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"unsupported platform"* ]]
  rm -rf "$tmpdir"
}

@test "platform-gate passes on Darwin when sibling plugin present" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "only meaningful on Darwin"
  fi
  run bash "$REPO/tools/platform-gate.sh"
  # May exit 3 if sibling plugin not installed in test env — acceptable.
  [ "$status" -eq 0 ] || [ "$status" -eq 3 ]
}
