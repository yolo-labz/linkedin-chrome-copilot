# linkedin-chrome-copilot

LinkedIn / job-search copilot for Claude Code. Runs on macOS, drives Chrome through the [claude-mac-chrome](https://github.com/yolo-labz/claude-mac-chrome) sibling plugin, keeps all session memory in plain markdown, and ships with a PII-scanner CI gate so no real contact data ever lands in git.

## What it does

- **Resume** job-search sessions with full context from a persistent markdown save-state — no re-explaining.
- **Draft replies** with channel-aware tone (LinkedIn DM ≠ email ≠ WhatsApp).
- **Clipboard-handoff** fallback for React-locked UIs (LinkedIn compose, thread switcher).
- **Verify sends** by re-reading the DOM — never silently promote `pending` to `sent`.
- **Book Calendly slots** against a free-window + guardrails policy, always with explicit timezone labels.
- **Tailor CVs** per role with keyword-coverage reports and a dated filename convention.
- **Sync LinkedIn profile** edits across locale variants (EN + PT).
- **Guard deep-work blocks**, prefer async, inject a quarterly reset at quarter boundaries.

## Platform support

**macOS 13+ only.** Every skill exits early with a clear diagnostic on Linux / Windows. This is by design: Chrome automation goes through AppleScript under the hood (via the sibling plugin), which has no Linux / Windows equivalent.

## Prerequisites

- Google Chrome with at least one profile signed in.
- Claude Code.
- [claude-mac-chrome](https://github.com/yolo-labz/claude-mac-chrome) ≥ 1.1.1 installed alongside this plugin.
- `gh`, `jq`, `bats-core`, `shellcheck`, `shfmt` on `PATH` (`brew install bats-core shellcheck shfmt jq gh`).
- Optional: `pandoc` or `typst` for CV PDF rendering.

## Install

```bash
git clone https://github.com/yolo-labz/linkedin-chrome-copilot.git ~/code/linkedin-chrome-copilot
claude plugins install ~/code/linkedin-chrome-copilot
```

## Quickstart

See [docs/QUICKSTART.md](./docs/QUICKSTART.md) for the 8-step operator flow. First-run target: resume a session against fixture data in under 10 minutes.

## Privacy — no PII in fixtures (hard rule)

All fixtures committed to this repo are **100% synthetic**. Real contact data lives in a local-only alias map at `~/.config/linkedin-copilot/aliases.json` (chmod 600, gitignored, never leaves your machine). Every PR runs `tools/pii-scan.sh` against committed files; any hit on email / phone / Calendly URL / common-name blocklist fails the build.

If you contribute a fixture, **use obvious placeholders**: `contact-a7`, `recruiter at example dot invalid`, `calendly example slug`. See [docs/PII-POLICY.md](./docs/PII-POLICY.md).

## Architecture (one-liner)

Skills are single-purpose shell scripts; agents are prompt files that orchestrate skills; commands are slash-command entry points; hooks enforce platform + save-state load; schemas are JSON Schema (draft-07) validated against fixtures in CI. Chrome I/O is 100% delegated to `claude-mac-chrome` via `tools/chrome-shim.sh`. See [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md).

## License

MIT. See [LICENSE](./LICENSE).

## Security

Report vulnerabilities privately via GitHub Private Vulnerability Reporting. See [SECURITY.md](./SECURITY.md).
