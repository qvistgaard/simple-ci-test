publish:
	yq -i ".spec.chart.spec.version=\"$(Build.SourceBranchName)\"" fluxcd/base/helmrelease.yaml
	yq -i ".spec.ref.tag=\"$(Build.SourceBranchName)\"" fluxcd/base/helmrepository.yaml