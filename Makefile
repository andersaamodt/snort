SHELL := bash

# Collected shell sources for linting.
SH_SOURCES := $(shell find core/scripts modules -name '*.sh' -o -name '*.bats' | grep -v node_modules)
SH_SCRIPTS := $(shell find core/scripts modules -name '*.sh' | grep -v node_modules)

.PHONY: lint test coverage default

lint:
	shfmt -i 2 -sr -d $(SH_SOURCES)
	shellcheck -e SC1091 $(SH_SCRIPTS)

default: test

test:
	$(MAKE) -C core test
	bats modules/*/tests

coverage:
	bashcov --skip-uncovered -- bats modules/*/tests
