WITH_CONFIG ?= config.mk

-include $(WITH_CONFIG)

GIT_CHGLOG=git-chglog


GSEMVER?=gsemver
GSEMVER_FLAGS=
GSEMVER_BUMP_FLAGS=
ifeq ($(WITH_PRE_RELEASE),true)
	GSEMVER_BUMP_FLAGS += patch --pre-release alpha --pre-release-overwrite
else
	GSEMVER_BUMP_FLAGS += --branch-strategy='{"branchesPattern":"^$(RELEASE_BRANCH)$$","preRelease":false}'
endif


CRANE?=crane

RELEASE_BRANCH ?= ci/release
DEPLOY_BRANCH ?= ci/deploy
TRUNK_BRANCH ?= master
ENVIRONMENTS ?= test staging production

GIT ?= git
GIT_USER_NAME ?=Source2Sea CI/CD
GIT_USER_EMAIL ?=ci@source2sea.com
GIT_CREDENTIALS ?=





SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c




define run_component_targets
	@for t in $(1); do \
	  set -e; \
	  if make -q -f $${t}.mk $(2) >/dev/null 2>&1 || make -n -f $${t}.mk $(2) >/dev/null 2>&1; then \
	  	echo "🚀 Running component: $${t}.mk with target: $(2)"; \
	    echo $(MAKE) -f $${t}.mk $(2) WITH_CONFIG=$(WITH_CONFIG) $(3); \
	    $(MAKE) -f $${t}.mk $(2) WITH_CONFIG=$(WITH_CONFIG) $(3); \
	  else \
	    echo "⚠️ Skipping missing target in component: $${t}.mk / $(2)"; \
	  fi; \
	done
endef

.PHONY: run-% next-version git-ensure-branch git-check-clean git-config release

ci-release: git-ensure-branch
	$(GIT) merge -X theirs --no-edit origin/master
	@$(MAKE) run-version-apply run-quality-scan run-package changelog git-commit

ci-publish:
	@$(MAKE) run-publish

clean:
	@$(MAKE) run-clean
	rm .next-version


git-config:
	$(GIT) config --global --add safe.directory /workspace/source/source-code
	$(GIT) config credential.helper "store --file=$(GIT_CREDENTIALS)"
	$(GIT) config user.email "$(GIT_USER_EMAIL)"
	$(GIT) config user.name "$(GIT_USER_NAME)"


git-check-clean: git-config
	@if ! $(GIT) diff --quiet || ! $(GIT) diff --cached --quiet || [ -n "$$($(GIT) ls-files --others --exclude-standard)" ]; then \
		echo "❌ Working directory is not clean. Please commit or stash changes."; \
		git status; \
		exit 1; \
	else \
		echo "✅ Working directory is clean."; \
	fi

git-ensure-branch: git-check-clean
	@echo "🔍 Ensuring branch '$(RELEASE_BRANCH)' exists locally and tracks remote..."
	@if git ls-remote --exit-code --heads origin $(RELEASE_BRANCH) > /dev/null; then \
		echo "✅ Remote branch 'origin/$(RELEASE_BRANCH)' exists."; \
		git fetch --no-tags origin $(RELEASE_BRANCH):refs/remotes/origin/$(RELEASE_BRANCH); \
		if git rev-parse --verify $(RELEASE_BRANCH) > /dev/null 2>&1; then \
			echo "🔁 Local branch '$(RELEASE_BRANCH)' already exists. Switching..."; \
			git switch $(RELEASE_BRANCH); \
		else \
			echo "📥 Creating local tracking branch from origin/$(RELEASE_BRANCH)..."; \
			git switch --track origin/$(RELEASE_BRANCH); \
		fi; \
	else \
		echo "🔧 Remote branch does not exist. Creating from current branch..."; \
		git switch -c $(RELEASE_BRANCH); \
		echo "📤 Pushing new branch to remote and setting upstream..."; \
		git push -u origin $(RELEASE_BRANCH); \
	fi

git-commit: .next-version
	@$(MAKE) run-vcs
	git commit -a -m"Updated for next version $(shell cat $<) [skip ci]" || exit 0

git-tag: .next-version
	git tag --force v$(shell cat $<)

## tag-and-push: Tag, and push version
git-push: .next-version git-tag
	git push origin HEAD
	git push origin v$(shell cat $<)

next-version: .next-version

.next-version:
	@echo "🔍 Checking for version changes..."
	@$(GIT) fetch --tags
	@LATEST_TAG=$$($(GIT) tag --sort=-v:refname | grep '^v' | head -n 1); \
		[ -z "$$LATEST_TAG" ] && LATEST_TAG="v0.0.0"; \
	NEXT_VERSION=$$($(GSEMVER) bump $(GSEMVER_BUMP_FLAGS)); \
	echo "🏷️ Latest Git tag:    $$LATEST_TAG"; \
	echo "📈 Next candidate:     $$NEXT_VERSION"; \
	if [ "v$$NEXT_VERSION" = "$$LATEST_TAG" ]; then \
		echo "❌ No version bump detected. Nothing to release."; \
		exit 1; \
	else \
		echo "✅ Version bump detected: $$NEXT_VERSION"; \
		echo "$$NEXT_VERSION" > $@; \
		echo "📝 Wrote version to $@"; \
	fi

changelog: CHANGELOG.md

CHANGELOG.md: .next-version
	$(GIT_CHGLOG) --next-tag $(shell cat $<) --output $@
	@if ! git diff --quiet --cached -- CHANGELOG.md; then \
		echo "📦 CHANGELOG.md already staged."; \
	elif git diff --quiet -- CHANGELOG.md; then \
		echo "✅ CHANGELOG.md unchanged."; \
	else \
		echo "➕ Adding CHANGELOG.md to Git..."; \
		git add CHANGELOG.md; \
	fi

run-%: .next-version
	$(call run_component_targets,$(foreach c,$(COMPONENTS),$(c)),$*,VERSION=$(shell cat $?))