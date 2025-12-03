# app.Makefile provides the main targets for installing the application.
# It requires several APP_* variables defined as followed.
include ../app.Makefile
# crd.Makefile provides targets to install Application CRD.
include ../crd.Makefile
# Production repo
#REGISTRY ?= marketplace.gcr.io/google/redis-enterprise-operator
# Artifact repo
#REGISTRY := us-central1-docker.pkg.dev/proven-reality-226706/redis-market-place
# the repo the publish copies from?
REGISTRY := gcr.io/proven-reality-226706/redislabs
# CI registry
# REGISTRY ?= gcr.io/redislabs-k8s-dev-238506/gkemp-redis-ci
# gcloud.Makefile provides default values for REGISTRY and NAMESPACE derived from local
# gcloud and kubectl environments.
include ../gcloud.Makefile
include ../var.Makefile

$(info ---- REGISTRY = $(REGISTRY))

CHART_NAME := redis-operator
$(info ---- CHART_NAME = $(CHART_NAME))

REDIS_TAG ?= 8.0.2-41
$(info ---- REDIS_TAG = $(REDIS_TAG))

OPERATOR_TAG ?= 8.0.2-6
$(info ---- OPERATOR_TAG = $(OPERATOR_TAG))

# The repo to pull the operator image from Docker Hub registry.
OPERATOR_REPO ?= operator
$(info ---- OPERATOR_REPO = $(OPERATOR_REPO))

# Deployer tag is used for displaying versions in Producer Portal.
# Producer Portal requires a minor version tag, and it follows the semver.org officially recommended regex:
# /^(0|[1-9]\d*)\.(0|[1-9]\d*)$/
# please view: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
# The operator tag is converted to <major>.<major><minor><patch><build> to avoid leading zeros.
# e.g.: 8.0.2-2 is converted to 8.8022
# This can also have a different patch number from the OPERATOR_TAG to indicate
# a marketplace-only change
DEPLOYER_TAG ?= 6.021001
$(info ---- DEPLOYER_TAG = $(DEPLOYER_TAG))

# Override the default image tag for the deployer's base image (gcr.io/cloud-marketplace-tools/k8s/deployer_helm).
# The default tag is defined in https://github.com/GoogleCloudPlatform/click-to-deploy/blob/master/k8s/MARKETPLACE_TOOLS_TAG,
# and gets propagated into the Dockerfile in an absurdly convoluted way.
# The default tag is currently hardcoded to 0.12.2, which includes multiple critical-level vulnerabiilities that prevent publishing.
MARKETPLACE_TOOLS_TAG_OVERRIDE ?= 0.12.7
$(info ---- MARKETPLACE_TOOLS_TAG_OVERRIDE = $(MARKETPLACE_TOOLS_TAG_OVERRIDE))

# Tag the deployer image with modified version.
APP_DEPLOYER_IMAGE := $(REGISTRY)/deployer:$(DEPLOYER_TAG)

NAME ?= redis-enterprise-operator-ci
NAMESPACE ?= redis

APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)" \
}

TESTER_IMAGE ?= $(REGISTRY)/tester:$(OPERATOR_TAG)

.PHONY: dev/install
dev/install: crd/install | .build/app/dev
	.build/app/dev install \
	--deployer='$(APP_DEPLOYER_IMAGE)' --parameters='{"name": "redis-enterprise-operator", "namespace": "$(NAMESPACE)", "operator.nodeCpu": 5000, "operator.nodeMem": 16, "reportingSecret": "gs://cloud-marketplace-tools/reporting_secrets/fake_reporting_secret.yaml"}' | tee install.log


app/build:: .build/redis-enterprise-operator/deployer \
			.build/redis-enterprise-operator/primary \
			.build/redis-enterprise-operator/usage-meter \
			.build/redis-enterprise-operator/tester


.build/redis-enterprise-operator: | .build
	mkdir -p "$@"

.build/redis-enterprise-operator/deployer: deployer/* \
								  chart/**/* \
                                  schema.yaml \
								  .build/var/DEPLOYER_TAG \
                                  .build/var/APP_DEPLOYER_IMAGE \
                                  .build/var/MARKETPLACE_TOOLS_TAG \
                                  .build/var/REGISTRY \
                                  .build/var/OPERATOR_TAG \
								  .build/var/CHART_NAME \
                                  | .build/redis-enterprise-operator
	$(call print_target, $@)
	DOCKER_BUILDKIT=0 docker build \
	    --build-arg REGISTRY="$(REGISTRY)" \
	    --build-arg TAG="$(OPERATOR_TAG)" \
	    --build-arg CHART_NAME="$(CHART_NAME)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG_OVERRIDE)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"

# Operator image is the primary image for Redis Enterprise.
# Label the primary image with the same tag as deployer image.
# From the partner portal, primary image is queried using the same tag
# as deployer image. When pulling the image from docker hub use
# the redis native tag and push that image as primary image with deployer tag.
.build/redis-enterprise-operator/primary: .build/var/REGISTRY \
										  .build/var/OPERATOR_TAG \
                                          .build/var/DEPLOYER_TAG \
                                          | .build/redis-enterprise-operator
	$(call print_target, $@)
	docker pull redislabs/$(OPERATOR_REPO):$(OPERATOR_TAG)
	docker tag redislabs/$(OPERATOR_REPO):$(OPERATOR_TAG) "$(REGISTRY):$(OPERATOR_TAG)"
	docker push "$(REGISTRY):$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/usage-meter: usage-meter/* \
										  .build/var/REGISTRY \
                                          .build/var/OPERATOR_TAG \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd usage-meter \
	    && DOCKER_BUILDKIT=0 docker build --tag "$(REGISTRY)/usagemeter:$(OPERATOR_TAG)" .
	docker push "$(REGISTRY)/usagemeter:$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/tester: apptest/**/* \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd apptest/tester \
	    && DOCKER_BUILDKIT=0 docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"
