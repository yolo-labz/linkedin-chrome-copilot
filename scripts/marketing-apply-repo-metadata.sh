#!/usr/bin/env bash
# scripts/marketing-apply-repo-metadata.sh
#
# Idempotently sets the marketing surface on the GitHub repo:
#   - Description (<=120 chars, capability-only framing)
#   - Topics (3-10, GitHub topic-discovery surface)
#
# Run from an authenticated `gh` shell (gh auth login first). Safe to re-run;
# `gh api` PATCH/PUT are idempotent on identical payloads. Source of truth for
# the marketing copy is README.md `## Capability` and
# `## How linkedin-chrome-copilot compares`.
#
# Provenance: shipped with PR #41 (feat(marketing): hero + capability +
# comparison + diagram + OG). Mirrors the class-leader pattern from
# yolo-labz/wa PR #172.

set -euo pipefail

REPO="${REPO:-yolo-labz/linkedin-chrome-copilot}"

DESCRIPTION="LinkedIn workflow copilot for Claude Code. PII-gated. Delegates Chrome I/O to claude-mac-chrome."

# 8 topics, GitHub topic-discovery surface. Order does not matter; GitHub stores
# them lowercase + sorted on retrieval.
TOPICS_JSON='{"names":["linkedin","job-search","claude-code","chrome-automation","stealth","pii","macos","shell"]}'

echo "-> patching description on ${REPO}"
gh api -X PATCH "repos/${REPO}" -f description="${DESCRIPTION}" --jq '.description'

echo "-> putting topics on ${REPO}"
printf '%s' "${TOPICS_JSON}" | gh api -X PUT "repos/${REPO}/topics" --input - --jq '.names | join(", ")'

echo "done"
