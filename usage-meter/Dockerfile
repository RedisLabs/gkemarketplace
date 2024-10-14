FROM registry.access.redhat.com/ubi8-minimal

# Update base packages.
RUN microdnf update -y

# Install python 3.8 and requirements.
RUN microdnf install python38 && \
    pip3 install kubernetes requests && \
    microdnf remove python38-setuptools python38-pip

# Setup the usage-meter app.
RUN mkdir -p /app
COPY run.sh /app/
COPY common.py /app/
COPY meter.py /app/
COPY tier_pricing.py /app/
WORKDIR /app

ENTRYPOINT ["/bin/sh", "/app/run.sh"]
