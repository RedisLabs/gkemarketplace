FROM gcr.io/cloud-marketplace-tools/testrunner:0.1.2

ENV WAIT_FOR_READY_TIMEOUT 3600
ENV TESTER_TIMEOUT 3600

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl wget dnsutils netcat jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl
RUN chmod +x /usr/local/bin/kubectl
 
COPY tests/basic-suite.yaml /tests/basic-suite.yaml
COPY tester.sh /tester.sh

WORKDIR /
ENTRYPOINT ["/tester.sh"]
