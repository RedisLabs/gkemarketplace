include helper/app.Makefile
include helper/crd.Makefile
include helper/gcloud.Makefile
include helper/var.Makefile

OP_VERSION=5.4.6-1186
TAG ?= 1.11.0
REGISTRY ?= gcr.io/proven-reality-226706
METRICS_EXPORTER_TAG ?= v0.7.1

$(info ---- TAG = $(TAG))

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/redislabs/deployer:$(TAG)
NAME ?= redislabs-1

ifdef METRICS_EXPORTER_ENABLED
  METRICS_EXPORTER_ENABLED_FIELD = , "metrics.enabled": "$(METRICS_EXPORTER_ENABLED)"
endif

APP_PARAMETERS ?= { \
  "APP_INSTANCE_NAME": "$(NAME)", \
  "NAMESPACE": "$(NAMESPACE)", \
  "REPORTING_SECRET": "test-value" \
  $(METRICS_EXPORTER_ENABLED_FIELD) \
}

TESTER_IMAGE ?= $(REGISTRY)/redislabs/tester:$(TAG)


app/build:: .build/redislabs/deployer \
            .build/redislabs/redislabs \


.build/redislabs: | .build
	mkdir -p "$@"


.build/redislabs/deployer: deployer/* \
                           schema.yaml \
                           .build/var/APP_DEPLOYER_IMAGE \
                           .build/var/MARKETPLACE_TOOLS_TAG \
                           .build/var/REGISTRY \
                           .build/var/TAG \
                           | .build/redislabs
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/redislabs" \
	    --build-arg TAG="$(TAG)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


.build/redislabs/redislabs: .build/var/REGISTRY \
                            .build/var/TAG \
                            | .build/redislabs
	docker pull redislabs/operator:${OP_VERSION}
	docker tag  redislabs/operator:${OP_VERSION} \
	    "$(REGISTRY)/redislabs:$(TAG)"
	docker push "$(REGISTRY)/redislabs:$(TAG)"
	@touch "$@"


