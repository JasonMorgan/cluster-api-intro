#!/bin/bash

## We're going to get started with the quickstart
## https://cluster-api.sigs.k8s.io/user/quick-start.html

### You can use any kubernetes cluster to get started.
kind create cluster

k cluster-info

### Install the clusterctl tool
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.3/clusterctl-darwin-amd64 -o clusterctl
chmod +x ./clusterctl
sudo mv clusterctl /usr/local/bin/
clusterctl version

### Set our AWS Vars

export AWS_REGION=us-east-1 
export AWS_ACCESS_KEY_ID=MYACCESSKEYID
export AWS_SECRET_ACCESS_KEY=MYSECRETACCESSKEY
export AWS_SSH_KEY_NAME=MYKEYNAME
export AWS_CONTROL_PLANE_MACHINE_TYPE=t3.medium
export AWS_NODE_MACHINE_TYPE=t3.medium

### This is an IaaS dependant install and only applicable to aws. If you want help on your vSphere environment please reach out to us directly, engage folks on the cluster-api channel on the kubernetes slack, or contact your vmware team. You can find this tool here: https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases

clusterawsadm alpha bootstrap create-stack

### Encode our AWS creds
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm alpha bootstrap encode-aws-credentials)

### Prepare the IaaS
clusterctl init --infrastructure aws

### Generate Cluster config
#### Using simple defaults, you'll want more customization when you take this to production
clusterctl config cluster capi-intro --kubernetes-version v1.17.3 --control-plane-machine-count=1 --worker-machine-count=1 > capi-intro.yaml

### Applying our objects
kubectl apply -f capi-intro.yaml

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
