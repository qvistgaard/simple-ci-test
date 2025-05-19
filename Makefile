WITH_CONFIG ?= config.mk

-include $(WITH_CONFIG)

GIT_CHGLOG_EXECUTABLE?=./git-chglog
GIT_SEMVER_EXECUTABLE?=./git-semver

GSEMVER?=./gsemver
GSEMVER_FLAGS=
GSEMVER_BUMP_FLAGS=

ifeq ($(WITH_PRE_RELEASE),true)
  GSEMVER_BUMP_FLAGS := patch --pre-release alpha
endif

.PHONY: help all build test package deploy release

## help: Show this help
help:
	@echo ""
	@echo "🛠  Available Targets:"
	@echo ""
	@grep -E '^## [a-zA-Z0-9_-]+:' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

define run_component_targets
	@for t in $(1); do \
	  set -e; \
	  if make -q -f $${t}.mk $(2) >/dev/null 2>&1 || make -n -f $${t}.mk $(2) >/dev/null 2>&1; then \
	  	echo "\033[32m🚀 Running component: $${t}.mk with target: $(2)\033[0m"; \
	    echo $(MAKE) -f $${t}.mk $(2) WITH_CONFIG=$(WITH_CONFIG) $(3); \
	    $(MAKE) -f $${t}.mk $(2) WITH_CONFIG=$(WITH_CONFIG) $(3); \
	  else \
	    echo "\033[33m⚠️ Skipping missing target in component: $${t}.mk / $(2)\033[0m"; \
	  fi; \
	done
endef



.PHONY: run-%
run-%: .next-version
	$(call run_component_targets,$(foreach c,$(COMPONENTS),$(c)),$*,VERSION=$(shell cat $?))

## version-generate: Compute the next semantic version
version-generate: .next-version
.next-version:
	@echo "Checking for version changes..."
	@LATEST_TAG=$$(git tag --sort=-v:refname | grep '^v' | head -n 1 || echo v0.0.0); \
	NEXT_VERSION=$$(./gsemver bump $(GSEMVER_BUMP_FLAGS)); \
	echo "Latest Git tag:    $$LATEST_TAG"; \
	echo "Next candidate:    $$NEXT_VERSION"; \
	if [ "v$$NEXT_VERSION" = "$$LATEST_TAG" ]; then \
	  echo "❌ No version bump detected. Nothing to release."; \
	  exit 1; \
	else \
	  echo "✅ Version bump detected: $$NEXT_VERSION"; \
	  echo $$NEXT_VERSION > $@; \
	fi

## changelog: Compute the next semantic version
changelog: CHANGELOG.md
CHANGELOG.md:
	$(GIT_CHGLOG_EXECUTABLE) --output $@

## all: Run full pipeline: build + release + deploy
all: build package

ci: version-apply tag

## build: Generate version, apply it, test, and package
build:
	@$(MAKE) run-build

## version-apply: Apply version to all components
version-apply:
	@$(MAKE) run-version-apply

## test: Run tests on all components
test: build
	@$(MAKE) run-test

## package: Run Maven packaging
package: test
	@$(MAKE) run-package

## quality-scan: Run quality analysis on all components
quality-scan:
	@$(MAKE) run-quality-scan

## publish: Run all publish steps
publish: package oci-login quality-scan
	@$(MAKE) run-publish

## tag-and-push: Tag, and push version
vcs: .next-version
	@$(MAKE) run-vcs
	git commit -a -m"Updated for next verion $(shell cat $<)"

tag: .next-version vcs
	git tag $(shell cat $<)
	$(MAKE) -B .next-version WITH_PRE_RELEASE=true WITH_CONFIG=$(WITH_CONFIG)
	$(MAKE) version-apply WITH_CONFIG=$(WITH_CONFIG)
	$(MAKE) vcs WITH_CONFIG=$(WITH_CONFIG)

## tag-and-push: Tag, and push version
push: tag CHANGELOG.md
	# git add CHANGELOG.md
	# git commit CHANGELOG.md -m"updated changelog"

oci-login:
	# exit 1;

clean:
	@$(MAKE) run-clean
	rm .next-version

