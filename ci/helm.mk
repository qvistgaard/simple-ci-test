HELM_BASEDIR:=helm
HELM_DIRS := $(patsubst %/,%,$(filter %/,$(wildcard $(HELM_BASEDIR)/*/)))
HELM_LINT_FLAGS?=
HELM_EXECUTABLE?=helm

.PHONY: version-apply package test publish

package: $(HELM_DIRS:%=%.package)

test: $(HELM_DIRS:%=%.lint)

# publish:
	# find helm/ -mindepth 1 -maxdepth 1 -name '*.tgz' | xargs -i -n1 sh -c 'curl -vvv -f -u "$(chartmuseum-crds)" --data-binary "@$0" $(chartmuseum-url) || exit 255' {}

vcs:
	@grep -Fxq "/helm/*.tgz" .gitignore || { \
		echo "ERROR: ❌ /helm/*.tgz is missing from .gitignore"; \
		exit 1; \
	}

version-apply: $(HELM_DIRS:%=%.version)
	echo HELM-VERSION $(HELM_DIRS:%=%.version)

%.dependencies:
	$(HELM_EXECUTABLE) dependency update --skip-refresh $*

%.lint: %.dependencies
	$(HELM_EXECUTABLE) lint $(HELM_LINT_FLAGS) $*

%.version:
	yq -i ".version=\"$(VERSION)\"" $*/Chart.yaml || exit 255
	yq -i ".appVersion=\"$(VERSION)\"" $*/Chart.yaml || exit 255
	yq -i ".dependencies[].version |=\"$(VERSION)\"" $*/Chart.yaml || exit 255

%.package: %.lint
	@echo "Packaging  Helm chart: $*"
	$(HELM_EXECUTABLE) package --destination $(HELM_BASEDIR) $*