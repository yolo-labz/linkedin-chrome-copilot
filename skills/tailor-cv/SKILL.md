---
name: tailor-cv
description: Read base CV + job description, extract keyword overlap, reorder experience bullets by keyword density, emit CVVariant JSON + markdown file. Optional pandoc/typst PDF render.
trigger: command
command: lc-tailor
platform: darwin
inputs:
  - name: base_cv
    type: path
    default: $LC_CV_BASE_PATH
    required: false
  - name: jd_path
    type: path
    required: true
  - name: output_dir
    type: path
    default: $LC_CV_OUT_DIR
    required: false
  - name: render_pdf
    type: bool
    default: false
    required: false
outputs:
  - name: variant
    type: json
    schema: schemas/cv-variant.schema.json
---

# tailor-cv

Produce a tailored CV variant for a specific job description.

## Algorithm

1. Read base CV markdown (frontmatter + body).
2. Read JD markdown (frontmatter yields `org_slug`, `role_slug`).
3. Load curated keyword list from `fixtures/engineering-keywords.json`.
4. Flatten categories → lowercase keyword set K.
5. Tokenize JD body; compute `K_jd = K ∩ jd_tokens`.
6. Tokenize base CV body; compute `K_cv = K ∩ cv_tokens`.
7. Coverage = `|K_jd ∩ K_cv| / |K_jd|` as integer percent.
8. For each experience bullet, score = count of K_jd keywords present.
9. Reorder bullets within each role by descending score (stable for ties).
   **Do not rewrite bullets** — reorder only (R7 research decision).
10. Emit markdown to `${output_dir}/cv-{org_slug}-{role_slug}-{YYYYMMDD}.md`.
11. Emit CVVariant JSON conforming to `schemas/cv-variant.schema.json`.
12. If `--render-pdf` and `pandoc` or `typst` available, render alongside.

## Contract

```json
{
  "id": "01HXXXXXXXXXXXXXXXXXXXXXXX",
  "base_cv_ref": "fixtures/cv-base.example.md",
  "jd_ref": "fixtures/job-description.example.md",
  "org_slug": "acme-corp",
  "role_slug": "staff-backend-engineer",
  "keyword_coverage_pct": 87,
  "output_md_path": "/tmp/cv-acme-corp-staff-backend-engineer-20260416.md",
  "output_pdf_path": null,
  "created_iso": "2026-04-16T12:00:00Z"
}
```

## Invariants

- Never hallucinates new bullets. Reorders only.
- Never removes bullets — full bullet set preserved.
- Never rewrites personal details from frontmatter.
- Coverage threshold ≥ 80% is enforced by SC-008 (caller must check).
- No Chrome, no network. Pure local transformation.

## Runner

`skills/tailor-cv/run.sh` is the entry point.
