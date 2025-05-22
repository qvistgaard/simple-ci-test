WITH_CONFIG ?= config.mk

-include $(WITH_CONFIG)

SONAR_URL ?=
SONAR_TOKEN ?=

MAVEN_WRAPPER_SCRIPT ?= ./mvnw
MAVEN_FLAGS ?= --batch-mode

MAVEN_JIB_USE_ROOT ?= false
MAVEN_JIB_MODULES ?=

CRANE ?= crane
CRANE_FLAGS ?=

ifeq ($(MAVEN_JIB_USE_ROOT),true)
  JIB_TARGETS := $(MAVEN_JIB_ROOT_IMAGE_NAME) $(MAVEN_JIB_MODULES)
else
  JIB_TARGETS := $(MAVEN_JIB_MODULES)
endif

ifeq ($(wildcard $(MAVEN_WRAPPER_SCRIPT)),)
	MAVEN ?= $(shell which mvn)
else
	MAVEN ?= $(MAVEN_WRAPPER_SCRIPT)
endif

define tarball_path
	$(if $(filter $(MAVEN_JIB_ROOT_IMAGE_NAME),$(1)),target/jib-image.tar,$(1)/target/jib-image.tar)
endef

.PHONY: build test clean

build:
	$(MAVEN) $(MAVEN_FLAGS) compile

test:
	$(MAVEN) $(MAVEN_FLAGS) test

clean:
	$(MAVEN) clean

package: package-maven $(addprefix package-,$(JIB_TARGETS))

package-%:
	$(MAVEN) $(MAVEN_FLAGS) jib:buildTar

package-maven:
	$(MAVEN) $(MAVEN_FLAGS) -DskipTests package

# Push tarball using crane
publish-%:
	@if [ -n "$(IMAGE_REPOSITORY)" ]; then \
		$(CRANE) push $(CRANE_FLAGS) $(call tarball_path,$*) $(IMAGE_REPOSITORY)/$*:$(VERSION); \
	else \
		echo "Skipping pushing docker image. no repository configured"; \
	fi

publish: $(addprefix publish-,$(JIB_TARGETS))

quality-scan:
	@if [ -n "$(SONAR_URL)" ] && [ -n "$(SONAR_TOKEN)" ]; then \
		$(MAVEN) $(MAVEN_FLAGS)  sonar:sonar -Dsonar.host.url=$(SONAR_URL) -Dsonar.token=$(SONAR_TOKEN); \
	else \
		echo "Skipping sonarqube analysis."; \
	fi


version-apply:
	$(MAVEN) versions:set -DnewVersion=$(VERSION)

vcs:
	@grep -Fxq "pom.xml.versionsBackup" .gitignore || { \
		echo "ERROR: ❌ pom.xml.versionsBackup is missing from .gitignore"; \
		exit 1; \
	}


