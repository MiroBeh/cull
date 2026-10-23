# Shorthand for the scripts in scripts/, which stay the source of truth: every
# target here is one line that calls one of them. Run `make` for the list.
#
# Flags are passed as variables (`make sim PHOTOS=40`), and anything a target
# has no variable for goes through ARGS (`make test ARGS="-- -quiet"`). Any
# non-empty value turns a switch on, so ERASE=0 still erases.

SHELL := /bin/bash
.DEFAULT_GOAL := help

SIM_FLAGS := \
	$(if $(PHOTOS),--photos $(PHOTOS)) \
	$(if $(MEDIA),--media $(MEDIA)) \
	$(if $(ERASE),--erase) \
	$(if $(GRANT),--grant) \
	$(if $(REVOKE),--revoke) \
	$(if $(CONSOLE),--console)

TEST_FLAGS := \
	$(if $(CLEAN),--clean) \
	$(if $(FILTER),--filter $(FILTER))

INSTALL_FLAGS := \
	$(if $(RELEASE),--release) \
	$(if $(NO_BACKUP),--no-backup) \
	$(if $(NO_LAUNCH),--no-launch)

.PHONY: help doctor sim test install backup restore logs files devices clean

help: ## Show this list
	@printf '\033[1mRummage\033[0m — make <target> [VAR=value]\n\n'
	@awk 'BEGIN { FS = ":.*## " } /^[a-z][a-z-]*:.*## / \
		{ printf "  \033[1m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf '\nDetail: docs/WORKFLOW.md\n'

doctor: ## Check the toolchain, signing and your phone
	@./scripts/doctor.sh $(ARGS)

sim: ## Build and run in a simulator (PHOTOS=40 MEDIA=dir ERASE=1 GRANT=1 REVOKE=1 CONSOLE=1)
	@./scripts/sim.sh $(SIM_FLAGS) $(ARGS)

test: ## Run the unit tests (FILTER=Suite/test CLEAN=1)
	@./scripts/test.sh $(TEST_FLAGS) $(ARGS)

install: ## Back up, build and install on your iPhone (RELEASE=1 NO_BACKUP=1 NO_LAUNCH=1)
	@./scripts/device.sh install $(INSTALL_FLAGS) $(ARGS)

backup: ## Copy the app's state off your iPhone into backups/
	@./scripts/device.sh backup $(ARGS)

restore: ## Put a backup back on your iPhone (BACKUP=backups/DIR)
	@[[ -n "$(BACKUP)" ]] || { echo "restore needs BACKUP=<dir>, e.g. make restore BACKUP=$$(ls -d backups/* 2>/dev/null | tail -1)"; exit 1; }
	@./scripts/device.sh restore $(BACKUP)

logs: ## Launch on your iPhone with the console attached
	@./scripts/device.sh logs

files: ## List the app's files on your iPhone (SUBDIR=Library)
	@./scripts/device.sh files $(if $(SUBDIR),$(SUBDIR))

devices: ## List the devices this Mac can see
	@./scripts/device.sh list

clean: ## Remove build output (never touches backups/)
	@rm -rf build
	@echo "Removed build/"
