ARG MARKETPLACE_TOOLS_TAG

FROM marketplace.gcr.io/google/debian11 AS build

ARG CHART_NAME

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext jq \
    && apt remove golang

ADD chart/$CHART_NAME /tmp/chart
RUN cd /tmp && tar -czvf /tmp/$CHART_NAME.tar.gz chart

ADD apptest/deployer/$CHART_NAME /tmp/test/chart
RUN cd /tmp/test \
    && tar -czvf /tmp/test/$CHART_NAME.tar.gz chart/

ADD schema.yaml /tmp/schema.yaml

ARG REGISTRY
ARG TAG

RUN cat /tmp/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /tmp/schema.yaml.new \
    && mv /tmp/schema.yaml.new /tmp/schema.yaml

ADD apptest/deployer/schema.yaml /tmp/apptest/schema.yaml
RUN cat /tmp/apptest/schema.yaml \
   | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
   > /tmp/apptest/schema.yaml.new \
   && mv /tmp/apptest/schema.yaml.new /tmp/apptest/schema.yaml

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:$MARKETPLACE_TOOLS_TAG

ARG CHART_NAME

LABEL com.googleapis.cloudmarketplace.product.service.name="Redis-Enterprise"

ENV WAIT_FOR_READY_TIMEOUT 3600
ENV TESTER_TIMEOUT 3600

COPY --from=build /tmp/$CHART_NAME.tar.gz /data/chart/
COPY --from=build /tmp/test/$CHART_NAME.tar.gz /data-test/chart/
COPY --from=build /tmp/apptest/schema.yaml /data-test/
COPY --from=build /tmp/schema.yaml /data/

RUN mkdir -p /crd_to_create
ADD deployer/rec_crd.yaml /crd_to_create/rec_crd.yaml
ADD deployer/redb_crd.yaml /crd_to_create/redb_crd.yaml
ADD deployer/rerc_crd.yaml /crd_to_create/rerc_crd.yaml
ADD deployer/reaadb_crd.yaml /crd_to_create/reaadb_crd.yaml
