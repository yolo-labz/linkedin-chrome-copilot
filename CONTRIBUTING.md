# Contributing

Thanks for considering a contribution. This repo is small, opinionated, and has a few hard rules.

## Hard rules

1. **No PII in committed files.** Fixtures must be 100% synthetic. `tools/pii-scan.sh` runs in pre-commit and CI. Any match on email / phone / Calendly URL / common-name blocklist fails the build.
2. **Never push to `main`.** Feature branch → PR → squash-merge. CI must be green before merge.
3. **Shell must be `shellcheck` + `shfmt` clean.** No exceptions. Pre-commit enforces.
4. **macOS 13+ baseline** (`bash` 3.2 compatible). No `declare -A`, no `mapfile`, no `readarray`, no `${var^^}` / `${var,,}`.
5. **No raw AppleScript in this repo.** All browser I/O goes through `tools/chrome-shim.sh` → sibling `claude-mac-chrome` plugin.

## Workflow

```bash
# fork, clone, then:
git checkout -b NNN-short-description
# make changes, run tests locally:
bats tests/bats/
tools/pii-scan.sh
bash tests/fixtures-validate.sh
# sign off and commit:
git commit -s -m "feat: your description"
# push and open a PR:
git push -u origin HEAD
gh pr create
```

## Commit format

Conventional commits, enforced by `commitlint` + `lefthook`:

- `feat:` new feature
- `fix:` bug fix
- `refactor:` code restructure, no behavior change
- `chore:` maintenance (deps, CI, tooling)
- `docs:` docs only
- `test:` tests only

Subject line ≤ 72 chars. DCO sign-off required (`git commit -s`).

## Dependencies

Runtime: `bash` 3.2+, `jq`, `pbcopy`/`pbpaste`, `osascript` (all macOS built-in or trivially installable). Dev: `bats-core`, `shellcheck`, `shfmt`, `pre-commit`, `gh`, `git-cliff`.

## Security

Report vulnerabilities via GitHub Private Vulnerability Reporting. Do not open public issues for security problems. See [SECURITY.md](./SECURITY.md).
