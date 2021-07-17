# app.Makefile provides the main targets for installing the application.
# It requires several APP_* variables defined as followed.
include ../app.Makefile
# crd.Makefile provides targets to install Application CRD.
include ../crd.Makefile
# gcloud.Makefile provides default values for REGISTRY and NAMESPACE derived from local
# gcloud and kubectl environments.
include ../gcloud.Makefile
include ../var.Makefile

# Production repo
#REGISTRY ?= marketplace.gcr.io/google/redis-enterprise-operator
# Artifact repo
#REGISTRY := us-central1-docker.pkg.dev/proven-reality-226706/redis-market-place
# Container repo
REGISTRY := gcr.io/proven-reality-226706/redislabs

$(info ---- REGISTRY = $(REGISTRY))

CHART_NAME := redis-operator
$(info ---- CHART_NAME = $(CHART_NAME))

REDIS_TAG ?= 6.0.20-97
$(info ---- REDIS_TAG = $(REDIS_TAG))

OPERATOR_TAG ?= 6.0.20-12
$(info ---- OPERATOR_TAG = $(OPERATOR_TAG))

# Deployer tag is used for displaying versions in partner portal.
# This version only support major.minor so the Redis version major.minor.patch
# is converted into more readable form of major.2 digit zero padded minor + patch
# without the hyphen
DEPLOYER_TAG ?= 6.002012
$(info ---- DEPLOYER_TAG = $(DEPLOYER_TAG))

# Tag the deployer image with modified version.
APP_DEPLOYER_IMAGE := $(REGISTRY)/deployer:$(DEPLOYER_TAG)

NAME ?= redis-enterprise-operator-1
NAMESPACE ?= redis

APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)" \
}

TESTER_IMAGE ?= $(REGISTRY)/tester:$(OPERATOR_TAG)

app/build:: .build/redis-enterprise-operator/deployer \
			.build/redis-enterprise-operator/primary \
			.build/redis-enterprise-operator/usage-meter \
            .build/redis-enterprise-operator/tester


.build/redis-enterprise-operator: | .build
	mkdir -p "$@"

.build/redis-enterprise-operator/deployer: deployer/* \
								  chart/**/* \
                                  schema.yaml \
                                  .build/var/APP_DEPLOYER_IMAGE \
                                  .build/var/MARKETPLACE_TOOLS_TAG \
                                  .build/var/REGISTRY \
                                  .build/var/OPERATOR_TAG \
								  .build/var/CHART_NAME \
                                  | .build/redis-enterprise-operator
	$(call print_target, $@)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)" \
	    --build-arg TAG="$(OPERATOR_TAG)" \
	    --build-arg CHART_NAME="$(CHART_NAME)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
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
	docker pull redislabs/operator:$(OPERATOR_TAG)
	docker tag redislabs/operator:$(OPERATOR_TAG) "$(REGISTRY):$(OPERATOR_TAG)"
	docker push "$(REGISTRY):$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/usage-meter: usage-meter/**/* \
										  .build/var/REGISTRY \
                                          .build/var/OPERATOR_TAG \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd usage-meter \
	    && docker build --tag "$(REGISTRY)/usagemeter:$(OPERATOR_TAG)" .
	docker push "$(REGISTRY)/usagemeter:$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/tester: apptest/**/* \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"
