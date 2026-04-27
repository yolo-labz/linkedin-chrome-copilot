# linkedin-chrome-copilot

Claude Code plugin that drives LinkedIn workflows on macOS Chrome via the [claude-mac-chrome](https://github.com/yolo-labz/claude-mac-chrome) sibling plugin. Per-locale profile-edit forms, message-triage routing, profile audit. Plain markdown save-state, PII-scanner CI gate, no committed contact data.

## Capabilities

- **Per-locale profile edits** — drives `/details/experience/edit/forms/<id>/?language=<lang>&country=<cc>` saves across PT/EN/ES locale slots via `execCommand('insertText')` + Save-button event-chain click.
- **Message triage** — channel-aware drafting (LinkedIn DM tone ≠ email tone ≠ WhatsApp tone) gated through guardrails policy.
- **Send verification** — re-reads DOM after every send; never silently promotes `pending` to `sent`.
- **Calendar slot booking** — free-window check against guardrails policy + explicit timezone labels on every output.
- **Document tailoring** — keyword-coverage reports + dated filename convention for per-target document variants.
- **Locale-variant sync** — propagates profile edits across EN + PT + ES slots with diff verification.
- **Workflow guardrails** — deep-work block guard, async-preference enforcement, quarterly reset injection at quarter boundaries.

## Platform support

**macOS 13+ only.** Every skill exits early with a clear diagnostic on Linux / Windows. By design: Chrome automation goes through AppleScript via the sibling plugin, which has no Linux / Windows equivalent.

## Prerequisites

- Google Chrome with at least one profile signed in.
- Claude Code.
- [claude-mac-chrome](https://github.com/yolo-labz/claude-mac-chrome) ≥ 1.1.1 installed alongside this plugin.
- `gh`, `jq`, `bats-core`, `shellcheck`, `shfmt` on `PATH` (`brew install bats-core shellcheck shfmt jq gh`).
- Optional: `pandoc` or `typst` for document PDF rendering.

## Install

```bash
git clone https://github.com/yolo-labz/linkedin-chrome-copilot.git ~/code/linkedin-chrome-copilot
claude plugins install ~/code/linkedin-chrome-copilot
```

## Quickstart

See [docs/QUICKSTART.md](./docs/QUICKSTART.md) for the 8-step operator flow. First-run target: resume a session against fixture data in under 10 minutes.

## Privacy — no PII in fixtures (hard rule)

All fixtures committed to this repo are **100% synthetic**. Real contact data lives in a local-only alias map at `~/.config/linkedin-copilot/aliases.json` (chmod 600, gitignored, never leaves your machine). Every PR runs `tools/pii-scan.sh` against committed files; any hit on email / phone / Calendly URL / common-name blocklist fails the build.

If you contribute a fixture, **use obvious placeholders**: `contact-a7`, `contact at example dot invalid`, `calendly example slug`. See [docs/PII-POLICY.md](./docs/PII-POLICY.md).

## Architecture (one-liner)

Skills are single-purpose shell scripts; agents are prompt files that orchestrate skills; commands are slash-command entry points; hooks enforce platform + save-state load; schemas are JSON Schema (draft-07) validated against fixtures in CI. Chrome I/O is 100% delegated to `claude-mac-chrome` via `tools/chrome-shim.sh`. See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## Sibling plugins

- [yolo-labz/claude-mac-chrome](https://github.com/yolo-labz/claude-mac-chrome) — required dependency. Drives Chrome via AppleScript JS-injection + cliclick.
- [yolo-labz/wa](https://github.com/yolo-labz/wa) — WhatsApp daemon. Composes with this plugin for cross-channel automation in one save-state.

## License

MIT. See [LICENSE](./LICENSE).

## Security

Report vulnerabilities privately via GitHub Private Vulnerability Reporting. See [SECURITY.md](./SECURITY.md).
