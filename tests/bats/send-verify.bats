#!/usr/bin/env bats
# send-verify.bats — T035 sent vs unconfirmed transitions.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TDIR="$(mktemp -d)"

  mkdir -p "$TDIR/claude-mac-chrome/lib" "$TDIR/claude-mac-chrome/.claude-plugin"

  cat > "$TDIR/claude-mac-chrome/.claude-plugin/plugin.json" <<'EOF'
{"name":"claude-mac-chrome","version":"1.1.1"}
EOF

  SIBLING_PARENT="$(mktemp -d)"
  ln -s "$REPO" "$SIBLING_PARENT/linkedin-chrome-copilot"
  ln -s "$TDIR/claude-mac-chrome" "$SIBLING_PARENT/claude-mac-chrome"
  export CLAUDE_PLUGIN_ROOT="$SIBLING_PARENT/linkedin-chrome-copilot"
}

teardown() {
  rm -rf "$TDIR"
}

@test "sent transition when DOM marker found" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  cat > "$TDIR/claude-mac-chrome/lib/chrome-lib.sh" <<'EOF'
chrome_execute_js() { echo "found"; }
chrome_fingerprint(){ echo fp; }
chrome_window_for() { echo w; }
chrome_focus_tab()  { :; }
chrome_catalog()    { :; }
chrome_check_inboxes() { :; }
chrome_open_tab()   { :; }
EOF
  run bash "$REPO/skills/send-verify/run.sh" --fingerprint fp1 --marker "hello" --timeout-ms 500 --alias contact-a7
  [ "$status" -eq 0 ]
  [[ "$output" == *'"state":"sent"'* ]]
}

@test "unconfirmed transition on timeout" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  cat > "$TDIR/claude-mac-chrome/lib/chrome-lib.sh" <<'EOF'
chrome_execute_js() { echo ""; }
chrome_fingerprint(){ echo fp; }
chrome_window_for() { echo w; }
chrome_focus_tab()  { :; }
chrome_catalog()    { :; }
chrome_check_inboxes() { :; }
chrome_open_tab()   { :; }
EOF
  run bash "$REPO/skills/send-verify/run.sh" --fingerprint fp1 --marker "hello" --timeout-ms 500 --alias contact-a7
  [ "$status" -eq 0 ]
  [[ "$output" == *'"state":"unconfirmed"'* ]]
}
