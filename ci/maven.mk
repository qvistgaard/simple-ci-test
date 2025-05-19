MAVEN_WRAPPER_SCRIPT ?= ./mvnw
MAVEN_FLAGS ?= --batch-mode

ifeq ($(wildcard $(MAVEN_WRAPPER_SCRIPT)),)
	MAVEN_EXECUTABLE ?= $(shell which mvn)
else
	MAVEN_EXECUTABLE ?= $(MAVEN_WRAPPER_SCRIPT)
endif

test:
	$(MAVEN_EXECUTABLE) test --batch-mode

clean:
	$(MAVEN_EXECUTABLE) clean

package:
	$(MAVEN_EXECUTABLE) package --batch-mode -Ddocker-repository=$(docker-repository)

quality-scan:
	# $(MAVEN_EXECUTABLE) sonar:sonar --batch-mode -Dsonar.host.url=$(sonarqube-url) -Dsonar.token=$(sonarqube-token)

version-apply:
	$(MAVEN_EXECUTABLE) versions:set -DnewVersion=$(VERSION)

vcs:
	@grep -Fxq "pom.xml.versionsBackup" .gitignore || { \
		echo "ERROR: ❌ pom.xml.versionsBackup is missing from .gitignore"; \
		exit 1; \
	}