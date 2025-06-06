WITH_CONFIG ?= config.mk

-include $(WITH_CONFIG)

GIT_CHGLOG=git-chglog

GSEMVER?=gsemver
GSEMVER_FLAGS=
GSEMVER_BUMP_FLAGS=

CRANE?=crane

RELEASE_BRANCH ?= ci/release
DEPLOY_BRANCH ?= ci/deploy
TRUNK_BRANCH ?= master
ENVIRONMENTS ?= test staging production

GIT ?= git
GIT_USER_NAME ?=
GIT_USER_EMAIL ?=
GIT_CREDENTIALS ?=


ifeq ($(WITH_PRE_RELEASE),true)
	GSEMVER_BUMP_FLAGS += patch --pre-release alpha --pre-release-overwrite
else
	GSEMVER_BUMP_FLAGS += --branch-strategy='{"branchesPattern":"^$(RELEASE_BRANCH)$$","preRelease":false}'
endif



.SHELLFLAGS := -eu -o pipefail -c




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

.PHONY: run-% next-version git-ensure-branch git-check-clean git-config release



ci-release: git-ensure-branch
	@$(MAKE) run-version-apply run-package run-quality-scan


git-config:
	git config --global --add safe.directory /workspace/source/source-code
	git config credential.helper "store --file=$(GIT_CREDENTIALS)"
	git config user.email "gocd@source2sea.com"
	git config user.name "GoCD @ Sourcv2Sea"
	git checkout -B master origin/master

git-check-clean: git-config
	@if ! $(GIT) diff --quiet || ! $(GIT) diff --cached --quiet || [ -n "$$($(GIT) ls-files --others --exclude-standard)" ]; then \
		echo "❌ Working directory is not clean. Please commit or stash changes."; \
		git status; \
		exit 1; \
	else \
		echo "✅ Working directory is clean."; \
	fi

git-ensure-branch: git-check-clean
	@echo "🔍 Ensuring branch '$(RELEASE_BRANCH)' exists locally and tracks remote..."; \
	@if $(GIT) ls-remote --exit-code --heads origin $(RELEASE_BRANCH) > /dev/null; then \
		echo "✅ Remote branch 'origin/$(RELEASE_BRANCH)' exists. Checking it out..."; \
		$(GIT) fetch --no-tags origin $(RELEASE_BRANCH):refs/remotes/origin/$(RELEASE_BRANCH); \
		$(GIT) switch --track origin$(RELEASE_BRANCH); \
	else \
		echo "🔧 Remote branch does not exist. Creating from current branch..."; \
		$(GIT) switch -c $(RELEASE_BRANCH); \
		echo "📤 Pushing new branch to remote and setting upstream..."; \
		$(GIT) push -u origin $(RELEASE_BRANCH); \
	fi

next-version: .next-version

.next-version:
	@echo "🔍 Checking for version changes..."; \
	LATEST_TAG=$$($(GIT) tag --sort=-v:refname | grep '^v' | head -n 1 || echo v0.0.0); \
	NEXT_VERSION=$$($(GSEMVER) bump --branch-strategy='{"branchesPattern":"^ci/release$$","preRelease":false}'); \
	@echo "🏷️  Latest Git tag:    $$LATEST_TAG"; \
	@echo "📈 Next candidate:     $$NEXT_VERSION"; \
	@if [ "v$$NEXT_VERSION" = "$$LATEST_TAG" ]; then \
		echo "❌ No version bump detected. Nothing to release."; \
		exit 1; \
	else \
		echo "✅ Version bump detected: $$NEXT_VERSION"; \
		echo "$$NEXT_VERSION" > $@; \
		echo "📝 Wrote version to VERSION.txt"; \
	fi


run-%: .next-version
	$(call run_component_targets,$(foreach c,$(COMPONENTS),$(c)),$*,VERSION=$(shell cat $?))