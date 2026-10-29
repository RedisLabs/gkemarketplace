#!/bin/bash
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

: "${NAMESPACE:?NAMESPACE must be set by the tester pod}"

kubectl version

timeout 300 bash -c '
  until kubectl get crd redisenterpriseclusters.app.redislabs.com; do
    echo "Waiting for RedisEnterpriseClusters CRD"
    sleep 5
  done
'

timeout 600 bash -c '
  state=""
  until [ "$state" = "Running" ]; do
    echo "Waiting for Redis Enterprise cluster to be running"
    state=$(kubectl get -n "$NAMESPACE" rec/redis-enterprise -o jsonpath="{.status.state}" 2>/dev/null || true)
    sleep 5
  done
'

timeout 1200 bash -c '
  set -e
  kubectl delete -n "$NAMESPACE" rec/redis-enterprise
  sleep 60
  kubectl delete -n "$NAMESPACE" deployment.apps/redis-enterprise-operator
  sleep 60
'
