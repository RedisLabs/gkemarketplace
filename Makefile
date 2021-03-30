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

REDIS_TAG ?= 6.0.12-57
$(info ---- REDIS_TAG = $(REDIS_TAG))

OPERATOR_TAG ?= 6.0.12-5
$(info ---- OPERATOR_TAG = $(OPERATOR_TAG))

APP_DEPLOYER_IMAGE := $(REGISTRY)/deployer:$(OPERATOR_TAG)

NAME ?= redis-enterprise-operator-1
NAMESPACE ?= redis

APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)" \
}

TESTER_IMAGE ?= $(REGISTRY)/tester:$(OPERATOR_TAG)

app/build:: .build/redis-enterprise-operator/deployer \
            .build/redis-enterprise-operator/redis \
			.build/redis-enterprise-operator/operator \
			.build/redis-enterprise-operator/k8s-controller \
			.build/redis-enterprise-operator/usage-meter \
			.build/redis-enterprise-operator/billing-agent \
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

.build/redis-enterprise-operator/tester: apptest/**/* \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
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

.build/redis-enterprise-operator/billing-agent: billing-agent/**/* \
										  .build/var/REGISTRY \
                                          .build/var/OPERATOR_TAG \
                                | .build/redis-enterprise-operator
	$(call print_target, $@)
	cd billing-agent \
	    && docker build --tag "$(REGISTRY)/billingagent:$(OPERATOR_TAG)" .
	docker push "$(REGISTRY)/billingagent:$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/redis: .build/var/REGISTRY \
                                          .build/var/REDIS_TAG \
                                          | .build/redis-enterprise-operator
	$(call print_target, $@)
	docker pull redislabs/redis:$(REDIS_TAG)
	docker tag redislabs/redis:$(REDIS_TAG) "$(REGISTRY)/redis:$(REDIS_TAG)"
	docker push "$(REGISTRY)/redis:$(REDIS_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/operator: .build/var/REGISTRY \
                                          .build/var/OPERATOR_TAG \
                                          | .build/redis-enterprise-operator
	$(call print_target, $@)
	docker pull redislabs/operator:$(OPERATOR_TAG)
	docker tag redislabs/operator:$(OPERATOR_TAG) "$(REGISTRY)/operator:$(OPERATOR_TAG)"
	docker push "$(REGISTRY)/operator:$(OPERATOR_TAG)"
	@touch "$@"

.build/redis-enterprise-operator/k8s-controller: .build/var/REGISTRY \
                                          .build/var/OPERATOR_TAG \
                                          | .build/redis-enterprise-operator
	$(call print_target, $@)
	docker pull redislabs/k8s-controller:$(OPERATOR_TAG)
	docker tag redislabs/k8s-controller:$(OPERATOR_TAG) "$(REGISTRY)/k8s-controller:$(OPERATOR_TAG)"
	docker push "$(REGISTRY)/k8s-controller:$(OPERATOR_TAG)"
	@touch "$@"


