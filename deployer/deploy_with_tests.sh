#!/bin/bash
#
# Copyright 2018 Google LLC
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

set -eox pipefail

# This is the entry point for the test deployment

# If any command returns with non-zero exit code, set -e will cause the script
# to exit. Prior to exit, set App assembly status to "Failed".
handle_failure() {
  code=$?
  if [[ -z "$NAME" ]] || [[ -z "$NAMESPACE" ]]; then
    # /bin/expand_config.py might have failed.
    # We fall back to the unexpanded params to get the name and namespace.
    NAME="$(/bin/print_config.py \
            --xtype NAME \
            --values_mode raw)"
    NAMESPACE="$(/bin/print_config.py \
            --xtype NAMESPACE \
            --values_mode raw)"
    export NAME
    export NAMESPACE
  fi
  patch_assembly_phase.sh --status="Failed"
  exit $code
}
trap "handle_failure" EXIT

LOG_SMOKE_TEST="SMOKE_TEST"
test_schema="/data-test/schema.yaml"
overlay_test_schema.py \
  --test_schema "$test_schema" \
  --original_schema "/data/schema.yaml" \
  --output "/data/schema.yaml"

NAME="$(/bin/print_config.py \
    --xtype NAME \
    --values_mode raw)"
NAMESPACE="$(/bin/print_config.py \
    --xtype NAMESPACE \
    --values_mode raw)"
export NAME
export NAMESPACE

echo "Checking other deployments" 
# make sure the operator is not deployed in this namespace and if it does fail the deployment
PREV_DEPLOY=$(kubectl get deploy redis-enterprise-operator --n $NAMESPACE -o name || true)
if [[ ! -z "$PREV_DEPLOY" ]]; then 
  echo "Cannot deploy, there is a redis operator already running in namespace $NAMESPACE"
  exit $?
fi

echo "Deploying application \"$NAME\" in test mode"

app_uid=$(kubectl get "applications.app.k8s.io/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.metadata.uid}')
app_api_version=$(kubectl get "applications.app.k8s.io/$NAME" \
  --namespace="$NAMESPACE" \
  --output=jsonpath='{.apiVersion}')

/bin/expand_config.py --values_mode raw --app_uid "$app_uid"

create_manifests.sh --mode="test"

# Assign owner references for the resources.
/bin/set_ownership.py \
  --app_name "$NAME" \
  --app_uid "$app_uid" \
  --app_api_version "$app_api_version" \
  --manifests "/data/manifest-expanded" \
  --dest "/data/resources.yaml"

separate_tester_resources.py \
  --app_uid "$app_uid" \
  --app_name "$NAME" \
  --app_api_version "$app_api_version" \
  --manifests "/data/resources.yaml" \
  --out_manifests "/data/resources.yaml" \
  --out_test_manifests "/data/tester.yaml"

export SERVICE_ACCOUNT="$(/bin/print_config.py \
    --xtype SERVICE_ACCOUNT \
    --values_mode raw)"

echo "Admin Service Account = $SERVICE_ACCOUNT"


shopt -s nocasematch
case "$INGRESS_AVAILABLE" in
	 "true"  ) export UI_SERVICE=LoadBalancer ;;
          *)  export UI_SERVICE=ClusterIP ;;
esac

# Put CRD in configmap so elvated Job can install it
kubectl create configmap crd-cm --from-file=crd=/bin/crd.yaml
# Create elavated job to create Job
envsubst < /bin/install-job.yaml.template > /bin/install-job.yaml
cat /bin/install-job.yaml
kubectl create -f /bin/install-job.yaml
# Wait for CRD job to finish and be available and then Apply the manifest.
sleep 10
CRDREADY=`kubectl get job redis-crd-installer  -o jsonpath="{.status.succeeded}"`
while [[ ${CRDREADY}  != 1 ]] ; do
  echo waiting for CRD job to complete
  sleep 2
  CRDREADY=`kubectl get job redis-crd-installer  -o jsonpath="{.status.succeeded}"`
done

# Apply the manifest.
kubectl apply --namespace="$NAMESPACE" --filename="/data/resources.yaml"

patch_assembly_phase.sh --status="Success"

wait_for_ready.py \
  --name $NAME \
  --namespace $NAMESPACE \
  --timeout ${WAIT_FOR_READY_TIMEOUT:-300}

tester_manifest="/data/tester.yaml"
if [[ -e "$tester_manifest" ]]; then
  cat $tester_manifest

  run_tester.py \
    --namespace $NAMESPACE \
    --manifest $tester_manifest \
    --timeout ${TESTER_TIMEOUT:-300}
else
  echo "$LOG_SMOKE_TEST No tester manifest found at $tester_manifest."
fi

clean_iam_resources.sh

trap - EXIT
