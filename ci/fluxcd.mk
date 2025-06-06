deploy: $(ENVIRONMENTS:%=%.deploy)
	echo $(ENVIRONMENTS)

%.deploy:
	yq -i ".spec.chart.spec.version=\"$(VERSION)\"" fluxcd/$*/helmrelease.yaml
	yq -i ".spec.ref.tag=\"v$(VERSION)\"" fluxcd/$*/helmrepository.yaml

