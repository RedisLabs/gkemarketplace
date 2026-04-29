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

# Fix CVE-2026-33186: replace helm binary with v4.1.4 which includes grpc fix
RUN wget -q -O /tmp/helm.tar.gz https://get.helm.sh/helm-v4.1.4-linux-amd64.tar.gz \
    && tar -zxf /tmp/helm.tar.gz -C /tmp \
    && mv /tmp/linux-amd64/helm /bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# RED-193212 - Install additional kubectl versions to avoid version skew warnings.
# The base image includes a wrapper script (/usr/bin/kubectl) that selects the best
# kubectl binary from /opt/kubectl/ based on the server version (±1 minor).
# Base image ships with 1.30 and 1.31. To support newer GKE versions, add versions here.
ARG KUBECTL_VERSIONS="1.34 1.35"
RUN for v in $KUBECTL_VERSIONS; do \
        mkdir -p "/opt/kubectl/$v"; \
        wget -q -O "/opt/kubectl/$v/kubectl" "https://dl.k8s.io/release/v${v}.0/bin/linux/amd64/kubectl"; \
        chmod +x "/opt/kubectl/$v/kubectl"; \
    done

ARG CHART_NAME

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
