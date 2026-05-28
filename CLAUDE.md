# CLAUDE.md

Guidance for Claude Code sessions working on `linkedin-chrome-copilot`. Drop-in
context so a fresh Claude can pick up without re-reading the whole repository.

## What this is

A Claude Code plugin that packages a LinkedIn / outreach / scheduling
copilot as skills, agents, and slash commands. All macOS Chrome browser I/O
is delegated to the sibling plugin
[`yolo-labz/claude-mac-chrome`](https://github.com/yolo-labz/claude-mac-chrome)
— this repo holds the workflow logic, schemas, fixtures, and CI gates only.

- **Repo:** https://github.com/yolo-labz/linkedin-chrome-copilot
- **Org:** `yolo-labz` (note the **z**, matches `claude-mac-chrome`)
- **License:** MIT
- **Manifest version:** `0.1.0-alpha` (pre-release; first signed tag pending)
- **Platform:** macOS 13+ only — skills exit early with a clear diagnostic
  on Linux / Windows.

## Why it exists

LinkedIn / outreach workflows on macOS Chrome have a few stable pain points
that warrant a packaged solution:

1. **Per-locale profile parity** — LinkedIn stores profile fields in separate
   locale slots (EN / PT / ES). Edits in one slot don't propagate; manual
   sync is error-prone. The `profile-sync` skill drives the locale-specific
   `/details/.../forms/<id>/?language=<lang>&country=<cc>` save flow.
2. **Channel-register drift** — LinkedIn DM tone ≠ email tone ≠ WhatsApp
   tone. `draft-reply` consults `config/registers.yaml` to pick the right
   register per channel before composing.
3. **Send-verify gap** — async chat UIs let "Draft → sent" promote silently
   on UI optimism. `send-verify` re-reads the DOM after every send and
   refuses to promote `pending → sent` without a confirmed match.
4. **No-PII committed fixtures** — operator data (contacts, Calendly URLs,
   real names) must never enter version control. `tools/pii-scan.sh` is a
   hard CI gate (exit 4 on any leak).
5. **Workflow guardrails** — deep-work block, hell-yes threshold,
   async-over-live preference, quarterly-reset cadence. Encoded in
   `config/guardrails.yaml`, enforced advisory via the `guardrails` skill.

## Architecture in one paragraph

Slash commands (`commands/lc-*.md`) trigger skills (`skills/<name>/SKILL.md` +
`run.sh`). Skills source `tools/platform-gate.sh` as their first non-comment
line (refuses non-Darwin + verifies sibling plugin), call `tools/chrome-shim.sh`
wrappers for any Chrome work (the shim is the **only** module that sources
`chrome-lib.sh` from the sibling plugin), and emit JSON contracts validated
against `schemas/*.schema.json` (draft-07). Agents (`agents/*.md`) orchestrate
multi-skill flows. Hooks under `hooks/` enforce platform-gate + save-state
load on `SessionStart` / `UserPromptSubmit`. Canonical persistence is a single
markdown save-state at `$LC_SAVESTATE_PATH` in the operator's vault; real
contact identities live ONLY in `~/.config/linkedin-copilot/aliases.json`
(chmod 600, gitignored, never in this repo).

## Repository layout

```
linkedin-chrome-copilot/
├── .claude-plugin/plugin.json    # plugin manifest (name, version, deps)
├── .github/workflows/            # ci, release, sonar, scorecard, osv-scanner
├── agents/                       # outreach-drafter, pipeline-curator
├── commands/                     # 6 slash commands: lc-{book,profile-sync,
│                                 #   quarterly,reply,resume,tailor}.md
├── config/                       # guardrails.yaml, registers.yaml
├── docs/                         # ARCHITECTURE.md, EXTEND.md, PII-POLICY.md
├── fixtures/                     # *.example.{json,md} — 100% synthetic
├── hooks/                        # SessionStart-*, UserPromptSubmit-*
├── schemas/                      # *.schema.json — JSON Schema draft-07
├── skills/                       # 10 skills, each <name>/{SKILL.md,run.sh}
│                                 #   book-slot, clipboard-handoff,         # stealth-allow: skill name
│                                 #   draft-reply, guardrails, profile-sync,
│                                 #   quarterly-reset, resume-session,
│                                 #   send-verify, tailor-cv,               # stealth-allow: skill name
│                                 #   watch-cancellation
├── tests/                        # bats/, fixtures-validate.sh
├── tools/                        # platform-gate, chrome-shim, pii-scan,
│                                 #   pii-blocklist
├── CHANGELOG.md                  # git-cliff (Keep a Changelog 1.1.0)
├── cliff.toml                    # git-cliff config
├── commitlint.config.js          # Conventional Commits enforcement
├── lefthook.yml                  # pre-commit + commit-msg + pre-push hooks
├── Makefile                      # lint / pii / fixtures / bats targets
├── LICENSE                       # MIT
└── README.md, SECURITY.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md
```

## Common commands

```bash
# Hard PII gate (pre-commit + CI). Exits 4 on any leak.
bash tools/pii-scan.sh

# Structural + JSON Schema (draft-07) fixture validation.
bash tests/fixtures-validate.sh

# bats-core suite — macOS only. Skipped with a notice on Linux.
bats tests/bats/

# Shell hygiene — shellcheck + shfmt + actionlint + zizmor.
shellcheck **/*.sh
shfmt -d -i 2 -ci **/*.sh
actionlint .github/workflows/*.yml
zizmor .github/workflows/

# All-in-one (lint + pii + fixtures).
make all
```

`Makefile` exposes `lint`, `pii`, `fixtures`, `bats` targets. The `bats`
target is a no-op on Linux by design (skills are macOS-only).

## Conventions

- **Conventional Commits** — enforced by `commitlint` via `lefthook.yml`.
  Allowed types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`.
  Note: `ci`, `style`, `perf`, `build` are NOT in the allowlist — use
  `chore` for CI / tooling changes. Subject ≤ 72 chars; DCO sign-off
  required (`git commit -s`).
- **Shell style** — bash 3.2 compatible (macOS baseline). No `declare -A`,
  no `mapfile`, no `readarray`, no `${var^^}` / `${var,,}`. `set -euo
  pipefail` at the top of every runnable script. `shellcheck` +
  `shfmt -i 2 -ci -bn` clean with no disables.
- **JSON Schema** — draft-07. All fixtures validate via `ajv-cli` in CI.
  Every schema declares `"$schema"`.
- **Skill shape** — `skills/<name>/SKILL.md` (frontmatter: name,
  description, trigger, command, platform) + `run.sh` (sources
  `platform-gate.sh` as the first non-comment line).
- **Naming** — slash commands prefixed `lc-` (LinkedIn copilot).

## Delegation pattern (NON-NEGOTIABLE)

All Chrome browser I/O delegates to `yolo-labz/claude-mac-chrome` via
`tools/chrome-shim.sh`. The shim wraps `chrome-lib.sh` from the sibling
plugin and exposes `lc_*` helpers. Skills call those helpers; **no skill
contains raw AppleScript**. This is enforced by:

1. `tools/chrome-shim.sh` being the only module that sources `chrome-lib.sh`.
2. A `no-raw-applescript` pre-commit hook (see `docs/ARCHITECTURE.md` §Boundaries).
3. The sibling plugin presence check inside `platform-gate.sh` (fails
   fast if `claude-mac-chrome` ≥ 1.1.1 is not installed).

Rationale: keep this repo browser-implementation-free so the sibling can
evolve its AppleScript layer independently, and so future ports
(`claude-linux-firefox`?) can swap the shim without touching workflow code.

## PII canon (HARD GATE)

`fixtures/` must remain **100% PII-free**. Real operator + contact data
never enters this repo. The boundary is enforced as:

- **`tools/pii-scan.sh`** — pre-commit + CI hard gate. Exits 4 on any
  hit against the email regex, E.164 phone regex, Calendly slug regex,
  magic-link token regex, or the configurable name blocklist
  (`tools/pii-blocklist.txt`).
- **Allowlist domains:** `*@example.invalid`, `*@example.com`,
  `*@example.org`, `noreply@*`, `*@github.com`,
  `*@users.noreply.github.com`. All-zero phones (`+00-000-000-0000`)
  pass.
- **Where real data lives** — only in the operator's filesystem:
  `~/.config/linkedin-copilot/aliases.json` (chmod 600, gitignored),
  `$LC_SAVESTATE_PATH`, `$LC_CV_BASE_PATH`. See `docs/PII-POLICY.md`.

Any contributor adding a fixture must use obvious placeholders
(`contact-a7`, `acme-corp`, `contact at example dot invalid`,
`calendly example slug`). If you discover a PII leak in history, open a
private advisory via `/security/advisories/new` — never a public issue.

## Release engineering — shared standards

Shared across all yolo-labz self-coded Claude Code plugins. Canonical
source: `~/NixOS/meta/yolo-labz-release-engineering-{research,plan}.md`
and the `plugin-release-engineering` rule auto-loaded into every Claude
Code session via home-manager.

- **Supply chain:** `actions/attest-build-provenance` +
  `actions/attest-sbom` (pinned by full SHA + `# vX.Y.Z` comment).
  CycloneDX 1.7 + SPDX 2.3 SBOMs via `syft` in `release.yml`. User
  verification via `gh attestation verify`.
- **GitHub Actions hardening:** workflow-level `permissions: {}`, per-job
  re-grant; `step-security/harden-runner` in audit mode on every
  workflow; `actions/checkout` with `persist-credentials: false`;
  `timeout-minutes` on every job.
- **Reproducibility:** `SOURCE_DATE_EPOCH=$(git log -1 --format=%ct)`
  before tarball creation; `tar --sort=name --owner=0 --group=0
  --numeric-owner --mtime="@${SOURCE_DATE_EPOCH}"`.
- **Never re-tag a release.** Cut `vX.Y.Z+1` on botched publishes —
  attestations bind to the commit SHA at signing time.
- **CHANGELOG.md** is auto-generated by `git-cliff` per `cliff.toml`
  (Keep a Changelog 1.1.0 format) — never hand-edited.

## Active state

- **Open PRs:** #39 (`chore(security): harden OpenSSF Scorecard workflow`)
  + Dependabot bumps (#36–#38).
- **First signed release tag:** pending (T51 in the rollout plan). Until
  cut, the README's release-verification section is aspirational.
- **Sibling parity:** sibling-of-fand class-leader; this CLAUDE.md is
  the Phase 4 `/init` artifact per spec
  `024-yolo-labz-portfolio-consolidation-2026Q2` plan §7 W5.

## Cross-references

- **Sibling plugin:** [`yolo-labz/claude-mac-chrome`](https://github.com/yolo-labz/claude-mac-chrome)
  — required dependency, ≥ 1.1.1.
- **Constitution v1.0.0:** `~/Documents/Notes/2. Areas/👷 Work/yolo-labz/`
  (Principle XII — delegation + PII gates).
- **Spec / plan / audit:** `~/Documents/Notes/1. Projects/specs/024-yolo-labz-portfolio-consolidation-2026Q2/`.
- **Repo docs:** `docs/ARCHITECTURE.md`, `docs/PII-POLICY.md`,
  `docs/EXTEND.md`, `CONTRIBUTING.md`, `SECURITY.md`.

## Invariants

1. Never re-tag a release. Cut `vX.Y.Z+1` on botched publishes.
2. Never commit a file containing real email / phone / Calendly URL /
   magic-link token / blocklisted name. `pii-scan.sh` is the hard gate.
3. Never inline raw AppleScript in a skill. All Chrome I/O goes through
   `tools/chrome-shim.sh`.
4. Never push directly to `main`. Feature branch → PR → squash-merge
   with green CI.
5. Never silently promote a Draft to `sent`. `send-verify` is the only
   path; failed verification stays `unconfirmed`.
6. `commitlint` type-enum: `feat|fix|refactor|chore|docs|test`. Use
   `chore` for CI / tooling changes (`ci` is NOT in the allowlist).
