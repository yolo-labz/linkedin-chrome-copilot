# Security Policy

## Reporting a vulnerability

Report privately via GitHub Private Vulnerability Reporting:
<https://github.com/yolo-labz/linkedin-chrome-copilot/security/advisories/new>

Do **not** open public issues for security problems.

## Supported versions

Only the latest `main` + the most recent tagged release receive fixes. This is a solo-maintained plugin; please keep expectations calibrated.

## Threat model

This plugin:

- Reads a local save-state markdown file.
- Reads a local alias map (`~/.config/linkedin-copilot/aliases.json`, chmod 600).
- Drives Chrome on macOS via the sibling `claude-mac-chrome` plugin.
- Touches the macOS clipboard (`pbcopy`).
- Creates a GitHub repo via `gh` at bootstrap time only.

It does **not**:

- Accept network connections.
- Upload data to any third-party service.
- Persist data outside the operator's machine.
- Bundle or ship any credentials.

If you find a path that violates any of the above, that's a vulnerability. Please report it.

## Scorecard + attestations

Releases ship with CycloneDX + SPDX SBOMs and GitHub-native build provenance attestations. Verify with a single command:

```bash
gh attestation verify <release-tarball> --repo yolo-labz/linkedin-chrome-copilot
```
