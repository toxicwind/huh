SHELL_SOURCES := \
	$(HOME)/.config/bash/main.sh \
	$(HOME)/.bashrc \
	$(HOME)/.bash_profile \
	$(HOME)/.profile \
	$(wildcard $(HOME)/.bashrc.d/*.sh)
SHELL_BINS := $(shell grep -l '^#!/usr/bin/env bash' $(HOME)/.local/bin-core/* 2>/dev/null || true)
SHELLCHECK_TARGETS := $(SHELL_SOURCES) $(SHELL_BINS)

.PHONY: check fmt lint test

check: fmt lint test

fmt:
	@shfmt -d $(SHELLCHECK_TARGETS)

lint:
	@shellcheck $(SHELLCHECK_TARGETS)

test:
	@bats -r tests
