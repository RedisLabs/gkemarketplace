FROM python:3.8-slim

RUN apt-get update && apt-get install -y curl
RUN pip install kubernetes requests
RUN mkdir -p /app
COPY run.sh /app/
COPY common.py /app/
COPY meter.py /app/
COPY tier_pricing.py /app/
WORKDIR /app

ENTRYPOINT ["/bin/sh", "/app/run.sh"]
