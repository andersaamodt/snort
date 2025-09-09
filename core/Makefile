.PHONY: wizard fetch render release test

wizard:
	./scripts/wizard.sh

fetch:
	./scripts/fetch.sh

render:
	./scripts/render_from_cache.sh

release:
	./scripts/release.sh

test:
	shfmt -i 2 -sr -d scripts tests
	shellcheck scripts/*.sh
	bats tests
