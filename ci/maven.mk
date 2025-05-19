WITH_CONFIG ?= config.mk

-include $(WITH_CONFIG)

MAVEN_WRAPPER_SCRIPT ?= ./mvnw
MAVEN_FLAGS ?= --batch-mode

MAVEN_JIB_USE_ROOT ?= false
MAVEN_JIB_MODULES ?=

CRANE_FLAGS ?=

ifeq ($(MAVEN_JIB_USE_ROOT),true)
  JIB_TARGETS := $(MAVEN_JIB_ROOT_IMAGE_NAME) $(MAVEN_JIB_MODULES)
else
  JIB_TARGETS := $(MAVEN_JIB_MODULES)
endif

ifeq ($(wildcard $(MAVEN_WRAPPER_SCRIPT)),)
	MAVEN_EXECUTABLE ?= $(shell which mvn)
else
	MAVEN_EXECUTABLE ?= $(MAVEN_WRAPPER_SCRIPT)
endif

ifdef CRANE_AUTH
  # CRANE_FLAGS += --auth=$(CRANE_AUTH)
endif

define tarball_path
	$(if $(filter $(MAVEN_JIB_ROOT_IMAGE_NAME),$(1)),target/jib-image.tar,$(1)/target/jib-image.tar)
endef

.PHONY: build test clean

build:
	$(MAVEN_EXECUTABLE) $(MAVEN_FLAGS) compile

test:
	$(MAVEN_EXECUTABLE) $(MAVEN_FLAGS) test

clean:
	$(MAVEN_EXECUTABLE) clean

package: package-maven $(addprefix package-,$(JIB_TARGETS))

package-%:
	$(MAVEN_EXECUTABLE) $(MAVEN_FLAGS) jib:buildTar

package-maven:
	$(MAVEN_EXECUTABLE) $(MAVEN_FLAGS) -DskipTests package

# Push tarball using crane
publish-%:
	./crane push $(CRANE_FLAGS) $(call tarball_path,$*) $(OCI_IMAGE_REPOSITORY)/$*:$(VERSION)

publish: $(addprefix publish-,$(JIB_TARGETS))

quality-scan:
	# $(MAVEN_EXECUTABLE) $(MAVEN_FLAGS)  sonar:sonar -Dsonar.host.url=$(sonarqube-url) -Dsonar.token=$(sonarqube-token)

version-apply:
	$(MAVEN_EXECUTABLE) versions:set -DnewVersion=$(VERSION)

vcs:
	@grep -Fxq "pom.xml.versionsBackup" .gitignore || { \
		echo "ERROR: ❌ pom.xml.versionsBackup is missing from .gitignore"; \
		exit 1; \
	}


