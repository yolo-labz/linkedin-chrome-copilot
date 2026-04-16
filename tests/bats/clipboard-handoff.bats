#!/usr/bin/env bats
# clipboard-handoff.bats — T034 via pbcopy mock.

setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  TDIR="$(mktemp -d)"
  # Stub pbcopy → writes stdin to a known file for assertion.
  cat > "$TDIR/pbcopy" <<EOF
#!/bin/sh
cat > "$TDIR/clipboard.out"
EOF
  chmod +x "$TDIR/pbcopy"
  # Stub chrome-lib.sh so lc_fingerprint and lc_focus_tab succeed deterministically.
  mkdir -p "$TDIR/claude-mac-chrome/lib" "$TDIR/claude-mac-chrome/.claude-plugin"
  cat > "$TDIR/claude-mac-chrome/lib/chrome-lib.sh" <<'EOF'
chrome_catalog()       { echo '{"profiles":[]}'; }
chrome_fingerprint()   { echo "fp-stub-$2"; }
chrome_window_for()    { echo "win-stub"; }
chrome_execute_js()    { echo "found"; }
chrome_focus_tab()     { echo "focused $1"; }
chrome_check_inboxes() { echo '{}'; }
chrome_open_tab()      { echo "tab-$1"; }
EOF
  cat > "$TDIR/claude-mac-chrome/.claude-plugin/plugin.json" <<'EOF'
{"name":"claude-mac-chrome","version":"1.1.1"}
EOF
  # Place the plugin repo in a sibling layout by symlinking.
  SIBLING_PARENT="$(mktemp -d)"
  ln -s "$REPO" "$SIBLING_PARENT/linkedin-chrome-copilot"
  ln -s "$TDIR/claude-mac-chrome" "$SIBLING_PARENT/claude-mac-chrome"
  export CLAUDE_PLUGIN_ROOT="$SIBLING_PARENT/linkedin-chrome-copilot"
  export PATH="$TDIR:$PATH"
}

teardown() {
  rm -rf "$TDIR"
}

@test "pbcopy receives body bytes" {
  if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
  printf 'hello from draft' | run bash "$REPO/skills/clipboard-handoff/run.sh" --profile work --url 'linkedin.com/messaging' --alias contact-a7
  [ "$status" -eq 0 ]
  clip="$(cat "$TDIR/clipboard.out")"
  [ "$clip" = "hello from draft" ]
  [[ "$output" == *'"event":"clipboard-handoff"'* ]]
}
