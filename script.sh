#!/bin/bash

## We're going to get started with the quickstart
## https://cluster-api.sigs.k8s.io/user/quick-start.html

### You can use any kubernetes cluster to get started.

#### We'll use kind for this example
#### Find more about kind here: https://kind.sigs.k8s.io/
##### Kind install

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.7.0/kind-$(uname)-amd64
chmod +x ./kind
sudo mv kind /usr/local/bin/

##### Start a local k8s cluster with kind
kind create cluster

alias k=kubectl
k cluster-info

### Install the clusterctl tool
#### What is it for?
#### For now we use this tool to generate the k8s cluster yaml templates that we hand off to cluster-API
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.3/clusterctl-$(uname)-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv clusterctl /usr/local/bin/
clusterctl version


### This is an IaaS dependant install and only applicable to aws. If you want help on your vSphere environment please reach out to us directly, engage folks on the cluster-api channel on the kubernetes slack, or contact your vmware team. 

### Set our AWS Vars

export AWS_REGION=us-east-1 
export AWS_ACCESS_KEY_ID=MYACCESSKEYID
export AWS_SECRET_ACCESS_KEY=MYSECRETACCESSKEY
export AWS_SSH_KEY_NAME=MYKEYNAME
export AWS_CONTROL_PLANE_MACHINE_TYPE=t3.medium
export AWS_NODE_MACHINE_TYPE=t3.medium

### You can find the clusterawsadm tool here: https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases
#### This section covers the install
curl -Lo clusterawsadm https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/download/v0.5.2/clusterawsadm-$(uname)-amd64
chmod +x clusterawsadm
sudo mv clusterawsadm /usr/local/bin/
clusterawsadm version

### Lets prep AWS!

clusterawsadm alpha bootstrap create-stack

### Encode our AWS creds
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

### Prepare the IaaS

#### Diff out the crds
### Octant: a UI for any given k8s cluster, learn more here: https://github.com/vmware-tanzu/octant

clusterctl init --infrastructure aws

### Generate Cluster config
#### Using simple defaults, you'll want more customization when you take this to production
clusterctl config cluster capi-intro --kubernetes-version v1.17.3 --control-plane-machine-count=1 --worker-machine-count=1 > capi-intro.yaml

### Dive into the lexicon and Control Plane Node/Manager node vs Deprecated Master node

### Applying our objects
kubectl apply -f capi-intro.yaml

#### Dig into the yaml

###In other windows
watch kubectl get cluster --all-namespaces

watch kubectl get kubeadmcontrolplane --all-namespaces

### Grab the kubeconfig for our new cluster

kubectl --namespace=default get secret/capi-intro-kubeconfig -o jsonpath={.data.value} \
  | base64 --decode \
  > ./capi-intro.kubeconfig

#### Lets add a CNI to get the cluster going

kubectl --kubeconfig=./capi-intro.kubeconfig \
  apply -f https://docs.projectcalico.org/v3.12/manifests/calico.yaml

watch kubectl --kubeconfig=./capi-intro.kubeconfig get nodes

##### Stretch Goal: Scale up Scale down
