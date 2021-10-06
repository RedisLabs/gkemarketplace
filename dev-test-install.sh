#!/usr/bin/env bash
mpdev install --deployer=gcr.io/proven-reality-226706/redislabs/deployer:6.002012 --parameters='{"name": "redis-enterprise-operator", "namespace": "redis", "operator.nodeCpu": 5000, "operator.nodeMem": 16, "reportingSecret": "gs://cloud-marketplace-tools/reporting_secrets/fake_reporting_secret.yaml"}' | tee install.log
