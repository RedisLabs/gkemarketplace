#!/usr/bin/env bash
gcloud container clusters create redis --zone us-central1-c --machine-type n2-standard-8
kubectl create ns redis
make crd/install
