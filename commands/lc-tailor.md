---
name: lc-tailor
description: Produce a tailored CV variant for a job description. Reorders base-CV bullets by JD keyword density; emits markdown + optional PDF.
platform: darwin
---

# /lc-tailor

## Usage

```
/lc-tailor --jd <path-to-jd.md> [--base <path-to-cv.md>] [--out-dir <dir>] [--render-pdf]
```

## Flow

1. Platform gate.
2. `skills/tailor-cv/run.sh` reads base CV + JD, extracts JD frontmatter for
   `org_slug` + `role_slug`, loads `fixtures/engineering-keywords.json`,
   computes keyword coverage, and reorders experience bullets by density.
3. Writes `cv-{org_slug}-{role_slug}-{YYYYMMDD}.md` to the output dir.
4. Emits `CVVariant` JSON conforming to `schemas/cv-variant.schema.json`.
5. Operator reviews; optionally renders to PDF via pandoc/typst.

## Guardrails

- Coverage < 80% → caller should fail SC-008 and surface a warning.
- Never rewrites bullets — reorders only (preserves factual content).
- Never removes bullets — full set preserved.
- No network, no Chrome.
