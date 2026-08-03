FROM registry.access.redhat.com/ubi8-minimal

# Update base packages to pull the latest RHSA-patched OS packages.
RUN microdnf update -y && microdnf clean all

# Install python 3.8 and requirements. Upgrade pip and the python deps so we don't
# ship stale, vulnerable versions.
RUN microdnf install python38 && \
    pip3 install --upgrade pip kubernetes requests && \
    microdnf remove python38-setuptools python38-pip

# Setup the usage-meter app.
RUN mkdir -p /app
COPY run.sh /app/
COPY common.py /app/
COPY meter.py /app/
COPY tier_pricing.py /app/
WORKDIR /app

ENTRYPOINT ["/bin/sh", "/app/run.sh"]
