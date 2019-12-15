# Overview

 

This bundles [Redis Enterprise](https://www.redislabs.com/) into a form suited to Google Cloud Platform Marketplace.


## Design

### Solution Information

Redis-Enterprise cluster is deployed within a Kubernetes StatefulSet.

The deployment creates two services:

- A client-facing one, designed to be used for client connections to the Redis-Enterprise
  cluster with port forwarding or using a LoadBalancer,
- Service discovery: a headless service for connections between
  the Redis-Enterprise nodes.

Redis-Enterprise Kubernetes application has the following ports configured: [TODO]


# Installation

## Quick install with Google Cloud Marketplace

Get up and running with a few clicks! Install this Redis Enterprise app to a
Google Kubernetes Engine cluster using Google Cloud Marketplace. You can do this from the Applications tab in the GKE page in the Cloud Console.

## Command line instructions
For testing, you may want to deploy straight from your command line, partially simulating what Marketplace does when it deploys. 

This is not a perfect simulation. For example, this entire process will not work unless you provide the [secrets](https://kubernetes.io/docs/concepts/configuration/secret/). 

Steps here are idempotent so feel free to just rerun steps in a script if you are working on later steps.


### Prerequisites

#### Set up command-line tools

You'll need the following tools in your development environment:

- [gcloud](https://cloud.google.com/sdk/gcloud/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [docker](https://docs.docker.com/install/)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Configure `gcloud` as a Docker credential helper:

```shell
gcloud auth configure-docker
```

#### Create a Google Kubernetes Engine cluster

Create a new cluster from the command line. The command is idempotent so runs after the first are not needed, but do no harm.

```shell
export CLUSTER=redis-cluster
export ZONE=us-west1-a

gcloud container clusters create "$CLUSTER" --zone "$ZONE"
```

Configure `kubectl` to connect to the new cluster.

```shell
gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE"
```

#### Clone this repo

Clone this repo and the associated tools repo.

```shell
git clone  https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
```

#### Install the Application resource definition

An Application resource is an addition to the Kubernetes metamodel: A collection of individual Kubernetes components, such as Services, Deployments, etc, that you can manage as a group.

The Application resource is defined by the [Kubernetes SIG-apps](https://github.com/kubernetes/community/tree/master/sig-apps) community. The source code can be found on
[github.com/kubernetes-sigs/application](https://github.com/kubernetes-sigs/application).

To add Application to the metamodel and thus set up your cluster to understand Application resources, run the following command. 

```shell
kubectl apply -f "https://raw.githubusercontent.com/GoogleCloudPlatform/marketplace-k8s-app-tools/master/crd/app-crd.yaml"
```

### Install the Application

Go to the `gkemarketplace` directory:

```shell
cd gkemarketplace
```

#### Configure the app with environment variables

Choose an instance name and[namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
for the app as follows. In most cases, you can use the `default` namespace.

```shell
export APP_INSTANCE_NAME=redis-labs-1
export NAMESPACE=default
```

Set the number of replicas:

```shell
export REPLICAS=3
```

Set the username for the app:

```shell
export REDIS_ADMIN=admin@acme.com
```

Set the CPU and Memory for nodes:

```shell 
export NODE_CPU=1000
export NODE_MEM=1
```


Configure the container images. Update version numbers as necessary.

```shell
export IMAGE_REDIS=gcr.io/proven-reality-226706/redislabs:1.11
export IMAGE_UBBAGENT=gcr.io/proven-reality-226706/redislabs/ubbagent:1.11
```

#### Create namespace in your Kubernetes cluster

Run the command below to create a new namespace. It is idempotent. 

```shell
kubectl create namespace "$NAMESPACE"
```

#### Prerequisites for using Role-Based Access Control

To use [role-based access control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) for the app,  grant your user the ability to create roles in
Kubernetes:

```shell
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)
```

For steps to enable role-based access control in Google Kubernetes Engine, see the [Kubernetes Engine documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/role-based-access-control).

#### Expand the manifest template

Use `envsubst` to expand the template. We recommend that you save the
expanded manifest file for future updates to the application.

1. Expand `RBAC` YAML file. You can  configure the RBAC first.

    ```shell
    # Define name of service account
    export SERVICE_ACCOUNT=redis-enterprise-operator
      
    # Expand rbac.yaml.template
    envsubst '$APP_INSTANCE_NAME $NAMESPACE $SERVICE_ACCOUNT' < manifest/rbac.yaml.template > "${APP_INSTANCE_NAME}_rbac.yaml"
    ```

1. Expand `Application`/`crd`/`operator`/`ConfigMap` YAML files.

    ```shell
     awk 'FNR==1 {print "---"}{print}' manifest/* \
     | envsubst '$APP_INSTANCE_NAME $NAMESPACE $IMAGE_REDIS $REPLICAS $REDIS_ADMIN $SERVICE_ACCOUNT $IMAGE_UBBAGENT $NODE_CPU $NODE_MEM' \
     > "${APP_INSTANCE_NAME}_manifest.yaml"
    ```

#### Apply the manifest to your Kubernetes cluster

Use `kubectl` to apply the manifest to your Kubernetes cluster:

```shell
kubectl apply -f "${APP_INSTANCE_NAME}_rbac.yaml" --namespace "${NAMESPACE}"
# crd.yaml: Custom Resource Definition
kubectl apply -f deployer/crd.yaml
kubectl apply -f "${APP_INSTANCE_NAME}_manifest.yaml" --namespace "${NAMESPACE}"
```

#### View the app in the Google Cloud Platform Console

Get the Google Cloud Console URL for your app, then open this URL in your browser:

```shell
echo "https://console.cloud.google.com/kubernetes/application/${ZONE}/${CLUSTER}/${NAMESPACE}/${APP_INSTANCE_NAME}"
```

#### Get the status of the cluster

By default, the application does not have an external IP address. Use `kubectl port-forward` to access the dashboard on the master
node at `localhost`.

```
kubectl port-forward redis-enterprise-cluster-0 8443

```

#### Getting the Admin Password

See [instructions here](https://docs.redislabs.com/latest/rs/faqs/).

####  Access the Redis-Enterprise service externally

```
kubectl get services -n $NAMESPACE
```

**NOTE:**

1. It might take some time for the external IP to be provisioned.
2. This works out-of-the-box in GKE but not in Anthos, where special measures are needed to configure the Load Balancer.


# Uninstall the Application

## Using the Google Cloud Platform Console

1. In the GCP Console, open [Kubernetes Applications](https://console.cloud.google.com/kubernetes/application).

1. From the list of applications, click **Redis-Enterprise**.

1. On the Application Details page, click **Delete**.

## Using the command line

### Prepare the environment

Set your installation name and Kubernetes namespace:

```shell
export APP_INSTANCE_NAME=redis-enterprise-1
export NAMESPACE=default
```

### Delete the resources

**NOTE:** We recommend to use a kubectl version that is the same as the version of your cluster .

To delete the resources, use the expanded manifest file used for the installation.

Run `kubectl` on the expanded manifest file:

```shell
kubectl delete -f "${APP_INSTANCE_NAME}_manifest.yaml" --namespace "${NAMESPACE}"
kubectl delete -f "${APP_INSTANCE_NAME}_rbac.yaml" --namespace "${NAMESPACE}"
```

Alternatively, delete the resources using types and a label:

```shell
kubectl delete statefulset,secret,service,configmap,serviceaccount,role,rolebinding,application \
  --namespace $NAMESPACE \
  --selector app.kubernetes.io/name=$APP_INSTANCE_NAME
```

### Delete the persistent volumes of your installation

By design, removal of StatefulSets in Kubernetes does not remove
PersistentVolumeClaims that were attached to their Pods. This prevents your
installations from accidentally deleting stateful data.

To remove the PersistentVolumeClaims with their attached persistent disks: 

```shell
for pv in $(kubectl get pvc --namespace $NAMESPACE \
  --selector app.kubernetes.io/name=$APP_INSTANCE_NAME \
  --output jsonpath='{.items[*].spec.volumeName}');
do
  kubectl delete pv/$pv --namespace $NAMESPACE
done

kubectl delete persistentvolumeclaims \
  --namespace $NAMESPACE \
  --selector app.kubernetes.io/name=$APP_INSTANCE_NAME
```

### Delete the GKE cluster

```
gcloud container clusters delete "$CLUSTER" --zone "$ZONE"
```

# Upgrading the version

When a few version of the Redis Operator comes out, you will want to upgrade the version. 

1. Upgrade `OP_VERSION=5.4.6-1186` in `Makefile`.
2. Increment `Makefile:TAG ?= 1.11` in `Makefile`. This will increment  the version of both this Marketplace package and the UBB image that provides the sidecar.
**Note**: Do not use a patch number like 1.12.0; use only major-minor.
3. `make -B app/build`  (where `-B` forces the build even if no change is detected).
   * This builds the image and pushes it to gcr.io

(`cloudbuild.yaml` allows building this in Cloud Buld instead of `make`. It is not yet in active use, pending permissions for triggers and adoption of a process. )