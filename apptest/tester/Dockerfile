# The smoke checks only need shell tools; the old testrunner base bundled an
# outdated Go binary that was only used to run these checks.
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    bash ca-certificates coreutils curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Lo /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x /usr/local/bin/kubectl

COPY tester.sh /tester.sh

WORKDIR /
ENTRYPOINT ["/tester.sh"]
