# PII Policy

`linkedin-chrome-copilot` is designed so that **no personally identifying
information (PII) about contacts or the operator lives in this repository**.

## What we consider PII

- Email addresses (except clearly synthetic: `*@example.invalid`, `*@example.com`,
  `*@example.org`, `noreply@*`)
- Phone numbers (except all-zero placeholders like `+00-000-000-0000`)
- Real names, surnames, handles of actual contacts
- Calendly event URLs (`calendly.com/<operator-handle>/...`)
- Magic-link login URLs (`?token=...`, `?key=...`, `?auth=...`)
- Resume / CV content tied to a real operator

## Where real data lives (never here)

| Data                         | Location                                            |
|------------------------------|-----------------------------------------------------|
| Real contact identities      | `~/.config/linkedin-copilot/aliases.json`           |
| Operator save-state          | `$LC_SAVESTATE_PATH` (e.g., Obsidian vault)         |
| Operator CV base             | `$LC_CV_BASE_PATH` (operator's private filesystem)  |
| Chrome session cookies       | OS keychain / Chrome profile dir                    |

## Enforcement

- **`tools/pii-scan.sh`** — pre-commit + CI hard gate. Exits 4 on any match.
- **Pre-commit hook `no-raw-applescript`** — blocks AppleScript strings from
  leaking into skills (skills must use `chrome-shim.sh` wrappers only).
- **`.gitignore`** excludes `aliases.json`, `config/secrets.*`, `*.pdf`,
  editor cruft.
- **Fixtures are synthetic**: `contact-a1..c3..g4`, `example-corp`,
  `+00-000-000-0000`, `acme-corp`.

## Contributor responsibilities

1. Never commit a file that contains a real email / phone / URL without
   running `bash tools/pii-scan.sh <file>` first.
2. Never copy operator save-state content into this repo — even as an example.
   Use the synthetic `fixtures/save-state.example.md` instead.
3. If you discover a PII leak in history, open a private advisory
   (`/security/advisories/new`) — do NOT file a public issue.

## Reporting

See `SECURITY.md` for the private-disclosure process.
