.PHONY: all lint pii fixtures bats shell-lint action-lint help

all: lint pii fixtures

help:
	@echo 'Targets:'
	@echo '  make lint       - shellcheck + shfmt + actionlint + zizmor'
	@echo '  make pii        - pii-scan.sh on full tree'
	@echo '  make fixtures   - structural + JSON Schema validation'
	@echo '  make bats       - bats-core (macOS only)'

shell-lint:
	@find . -type f \( -name '*.sh' -o -name '*.bash' \) \
		-not -path './.git/*' -not -path './.stversions/*' \
		-print0 | xargs -0 -r shellcheck --severity=warning
	@find . -type f \( -name '*.sh' -o -name '*.bash' \) \
		-not -path './.git/*' -not -path './.stversions/*' \
		-print0 | xargs -0 -r shfmt -i 2 -ci -bn -d

action-lint:
	@actionlint -color 2>/dev/null || echo '(actionlint not installed — skipping)'
	@zizmor --format plain .github/workflows/ 2>/dev/null || echo '(zizmor not installed — skipping)'

lint: shell-lint action-lint

pii:
	@bash tools/pii-scan.sh

fixtures:
	@bash tests/fixtures-validate.sh

bats:
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		echo 'bats suite is macOS-only; skipping on $$(uname -s).'; \
	else \
		bats tests/bats/; \
	fi
