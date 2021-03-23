# Overview

This repo is for building and deploying [Redis Enterprise](https://github.com/RedisLabs/redis-enterprise-k8s-docs) for GKE Market Place.   

## Design

### Solution Information

Redis-Enterprise cluster is deployed within a Kubernetes StatefulSet.

The deployment creates two services:

- A client-facing one, designed to be used for client connections to the Redis-Enterprise
  cluster with port forwarding or using a LoadBalancer,
- Service discovery: a headless service for connections between
  the Redis-Enterprise nodes.

# Build instructions

## Quick install with Google Cloud Marketplace

Get up and running with a few clicks! Install this Redis Enterprise app to a
Google Kubernetes Engine cluster using Google Cloud Marketplace. You can do this from the Applications tab in the GKE page in the Cloud Console.

### Prerequisites

#### Set up command-line tools

You'll need the following tools in your development environment:

- [gcloud](https://cloud.google.com/sdk/gcloud/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)
- [docker](https://docs.docker.com/install/)
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [marketplace tools](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/docs/tool-prerequisites.md)

Configure `gcloud` as a Docker credential helper:

```shell
gcloud auth login
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
Create a namespace where redis cluster and database should be created

```shell
kubectl create namespace redis
```

#### Clone the repos 


```shell
git clone https://github.com/GoogleCloudPlatform/click-to-deploy
cd k8s
git clone https://github.com/RedisLabs/gkemarketplace
```

```
Optional:  For reference, you can get  RedisLabs Enterprise K8s Operator code (i.e., unrelated to Google MP)
```shell
git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs.git
```

Optional: For reference, you can get  MP K8s tools, examples, and instructions
```shell
git clone https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools
```

#### Building

```shell
cd gkemarketplace
make clean
make app/build
```

#### Deploying to GKE

An Application resource is an addition to the Kubernetes metamodel: A collection of individual Kubernetes components, such as Services, Deployments, etc, that you can manage as a group.

The Application resource is defined by the [Kubernetes SIG-apps](https://github.com/kubernetes/community/tree/master/sig-apps) community. The source code can be found on
[github.com/kubernetes-sigs/application](https://github.com/kubernetes-sigs/application).


```shell
make crd/install
mpdev install --deployer=<deployer-repo> --parameters='{"name": "redis-enterprise-operator", "namespace": "redis", "operator.nodeCpu": 5000, "operator.nodeMem": 16, "reportingSecret": "gs://cloud-marketplace-tools/reporting_secrets/fake_reporting_secret.yaml"}
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

See [instructions here](https://docs.redislabs.com/latest/rs/faqs/) under "How to retrieve the username/password for a Redis Enterprise Cluster?"

In summary, `kubectl get secret redis-enterprise -o yaml|grep password|cut -d':' -f 2|base64 --decode` should get you the password, and you should already know the username (default `admin@example.com`)

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

