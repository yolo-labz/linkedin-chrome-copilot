# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

### Added

- resume-session skill + /lc-resume command (save-state parser).
- draft-reply, clipboard-handoff, send-verify skills + /lc-reply command.
- book-slot, watch-cancellation skills + /lc-book command.
- tailor-cv, profile-sync skills + /lc-tailor, /lc-profile-sync commands.
- guardrails, quarterly-reset skills + /lc-quarterly command.
- Release workflow with CycloneDX + SPDX SBOMs and build-provenance attestation.
- Architecture, PII policy, and extension docs.
- git-cliff configuration for automated CHANGELOG regeneration.

### Security

- pii-scan.sh hard gate in pre-commit + CI.
- no-raw-applescript pre-commit hook.
- Repository Ruleset + signed-releases baseline per yolo-labz standards.
