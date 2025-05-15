#!/usr/bin/env bash

### Step 1: Generate Version number
# Use https://github.com/PSanetra/git-semver
NEXT_VERSION=$(git-semver next --stable=false)

### Step 2: Update version numbers.

# Helm charts
find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".version=\"$(version)\"" $0 || exit 255' {}
find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".appVersion=\"$(version)\"" $0 || exit 255' {}
find -maxdepth 3 -type f -name Chart.yaml | xargs -i -n1 sh -c 'yq -i ".dependencies[].version |=\"$(version)\"" $0 || exit 255' {}

# FluxCD deployments
yq -i ".spec.chart.spec.version=\"$(Build.SourceBranchName)\"" fluxcd/base/helmrelease.yaml
yq -i ".spec.chart.spec.version=\"$(Build.SourceBranchName)\"" fluxcd/base/helmrepository.yaml

# Maven
mvn versions:set -DnewVersion=$(version)


### Step 3. Running Tests
# Helm lint
find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm dependency update --skip-refresh $0 || exit 255' {}
find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm lint $(HELM_LINT_OPTIONS) $0 || exit 255' {}

# Maven test
mvn test --batch-mode -Ddocker-repository=$(docker-repository)


### Step 4. Package
# Maven
mvn package --batch-mode -Ddocker-repository=$(docker-repository)

### Step 5. Generate metadata
# generate changelog: https://github.com/git-chglog/git-chglog

### Step 6. Tag and push

# Maven Sonar information
mvn sonar:sonar --batch-mode -Dsonar.host.url=$(sonarqube-url) -Dsonar.token=$(sonarqube-token)

# Git .. Git should keep track of modified and added files, and use that to commit to main branch
git add changelog
git commit changed files
git tag
git push

#### Step 7. Upload Artifacts
# Docker
docker images --format "{{.Repository}}:{{.Tag}}" | grep $(docker-repository) |sort | xargs -i docker push -q {}

# Helm
find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm dependency update --skip-refresh $0 || exit 255' {}
find helm/ -mindepth 1 -maxdepth 1 -type d  | xargs -i -n1 sh -c 'helm package --destination helm $0 || exit 255' {}
find helm/ -mindepth 1 -maxdepth 1 -name '*.tgz' | xargs -i -n1 sh -c 'curl -vvv -f -u "$(chartmuseum-crds)" --data-binary "@$0" $(chartmuseum-url) || exit 255' {}


