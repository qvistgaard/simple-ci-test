.PHONY: version-apply

publish:
	#
	echo "PUBLISH"

vcs:
	#
	echo "VCS"

clean:

package:
	find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm dependency update --skip-refresh $0 || exit 255' {}
	find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm package --destination helm $0 || exit 255' {}

test:
	find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm dependency update --skip-refresh $0 || exit 255' {}
	find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm lint $(HELM_LINT_OPTIONS) $0 || exit 255' {}

publish:
	find helm/ -mindepth 1 -maxdepth 1 -name '*.tgz' | xargs -i -n1 sh -c 'curl -vvv -f -u "$(chartmuseum-crds)" --data-binary "@$0" $(chartmuseum-url) || exit 255' {}

version-apply:
	find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".version=\"$(VERSION)\"" $0 || exit 255' {}
	find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".appVersion=\"$(VERSION)\"" $0 || exit 255' {}
	find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".dependencies[].version |=\"$(VERSION)\"" $0 || exit 255' {}
