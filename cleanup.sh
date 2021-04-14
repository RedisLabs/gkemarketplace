#!/usr/bin/env bash

kubectl delete job.batch/redis-enterprise-operator-cr-job
kubectl delete job.batch/redis-enterprise-operator-crd-job
