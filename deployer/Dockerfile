FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst:latest

COPY manifest/* /data/manifest/
ADD schema.yaml /data/

# Provide registry prefix and tag for default values for images.
ARG REGISTRY=gcr.io/proven-reality-226706/redislabs
ARG TAG=0.2.0

# Replace the original deploy with our deploy.sh that installs crd as first stage
ADD deployer/deploy.sh /bin/
ADD deployer/deploy_with_tests.sh /bin/
ADD deployer/install-job.yaml.template /bin/
ADD deployer/crd.yaml /bin/

RUN cat /data/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst \
    > /data/schema.yaml.new \
    && mv /data/schema.yaml.new /data/schema.yaml
