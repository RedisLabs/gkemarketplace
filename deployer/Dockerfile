ARG MARKETPLACE_TOOLS_TAG

FROM marketplace.gcr.io/google/debian12 AS build

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

# RED-193212 - Install additional kubectl versions to avoid version skew warnings.
# The base image includes a wrapper script (/usr/bin/kubectl) that selects the best
# kubectl binary from /opt/kubectl/<major>.<minor>/ based on the server version (±1 minor).
# Kubernetes 1.33 remains supported, so keep kubectl 1.34 available as its
# compatible next-minor client. Include kubectl 1.36 for Kubernetes 1.36 and
# upcoming 1.37 support. Use full patch versions here (x.y.z, not x.y.0).
ARG KUBECTL_VERSIONS="1.34.12 1.35.9 1.36.5"
RUN for v in $KUBECTL_VERSIONS; do \
        minor="${v%.*}"; \
        mkdir -p "/opt/kubectl/$minor"; \
        wget -q -O "/opt/kubectl/$minor/kubectl" "https://dl.k8s.io/release/v${v}/bin/linux/amd64/kubectl"; \
        chmod +x "/opt/kubectl/$minor/kubectl"; \
    done

ARG CHART_NAME

ENV WAIT_FOR_READY_TIMEOUT 3600
ENV TESTER_TIMEOUT 3600

COPY --from=build /tmp/$CHART_NAME.tar.gz /data/chart/
COPY --from=build /tmp/test/$CHART_NAME.tar.gz /data-test/chart/
COPY --from=build /tmp/apptest/schema.yaml /data-test/
COPY --from=build /tmp/schema.yaml /data/

RUN mkdir -p /crd_to_create
# Install all CRDs staged into the build context (synced from deploy/crds), so the
# operator's full CRD set is always installed without maintaining a list here.
ADD deployer/*_crd.yaml /crd_to_create/
