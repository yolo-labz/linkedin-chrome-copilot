# Extending linkedin-chrome-copilot

## Adding a new skill

1. Create `skills/<name>/SKILL.md`:

   ```markdown
   ---
   name: <name>
   description: <one-line, specific, ≤ 150 chars>
   trigger: command
   command: lc-<name>
   platform: darwin
   inputs:
     - name: <arg>
       type: <string|path|int|bool>
       required: <true|false>
   outputs:
     - name: result
       type: json
   ---

   # <name>

   ## Algorithm (numbered steps)
   ## Contract (JSON sample)
   ## Invariants (what the skill MUST NOT do)
   ```

2. Create `skills/<name>/run.sh`:

   ```bash
   #!/usr/bin/env bash
   set -eu
   _self="$(cd "$(dirname "$0")/../.." && pwd)"
   # shellcheck source=/dev/null
   . "${_self}/tools/platform-gate.sh"
   # ... or chrome-shim.sh if the skill needs Chrome
   ```

3. Make it executable: `chmod +x skills/<name>/run.sh`.

4. Add a slash command at `commands/lc-<name>.md` with usage + flow.

5. Add bats coverage at `tests/bats/<name>.bats`. Skip on non-Darwin:

   ```bash
   @test "..." {
     if [ "$(uname -s)" != "Darwin" ]; then skip "macOS-only"; fi
     run bash "$REPO/skills/<name>/run.sh" --flag value
     [ "$status" -eq 0 ]
   }
   ```

6. Run locally:

   ```bash
   bash tools/pii-scan.sh skills/<name>/
   bash tests/fixtures-validate.sh
   bats tests/bats/<name>.bats
   ```

## Adding a new agent

1. Create `agents/<name>.md`:

   ```markdown
   ---
   name: <name>
   description: <when to invoke this agent>
   tools: [Read, Grep, Glob]
   ---

   # <name>

   ## Invariants (hard rules)
   ## When to delegate to operator
   ## Context sources
   ```

2. Reference it from the relevant command(s).

## Adding a new guardrail

1. Append to `config/guardrails.yaml`:

   ```yaml
   rules:
     <rule_name>:
       enabled: true
       <param>: <value>
       reason: "..."
   ```

2. Add a branch in `skills/guardrails/run.sh` that reads the rule and appends
   a `{rule, reason}` to `_triggered` when violated.

3. Extend `tests/bats/guardrails.bats` with the deny/allow matrix.

## Adding a new channel

1. Append a block to `config/registers.yaml`:

   ```yaml
   channels:
     <channel>:
       max_chars: <int>
       tone: <casual|formal>
       greeting_style: <...>
       signoff: <...>
       forbidden: [<phrase>, ...]
   ```

2. Extend `skills/draft-reply/run.sh` channel dispatcher.

3. Add a fixture + bats case.

## Golden-path local test loop

```bash
make lint        # shellcheck + shfmt + actionlint + zizmor
make pii         # bash tools/pii-scan.sh
make fixtures    # bash tests/fixtures-validate.sh
make bats        # bats tests/bats/  (macOS only)
```

(Makefile lives under the `Polish` phase of the implementation plan.)
