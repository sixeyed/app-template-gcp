#!/bin/sh
mkdir -p /project/secrets

# parse parameters
gcpParameters=$(jq -c '.services | map(select(.serviceId == "gcp"))[0].parameters' /run/configuration)
saKeyEncoded=$(echo "$gcpParameters" | jq -c '.saKeyEncoded' --raw-output)
project=$(echo "$gcpParameters" | jq -c '.project' --raw-output)
zone=$(echo "$gcpParameters" | jq -c '.zone' --raw-output)

gkeParameters=$(jq -c '.services | map(select(.serviceId == "gke"))[0].parameters' /run/configuration)
gkeTemplate=$(echo "$gkeParameters" | jq -c '.gkeTemplate' --raw-output)
kubeVersion=$(echo "$gkeParameters" | jq -c '.kubeVersion' --raw-output)
nodeCount=$(echo "$gkeParameters" | jq -c '.nodeCount' --raw-output)

# authenticate - incoming key is base64
echo $saKeyEncoded | base64 -d > /tmp/service-account.json
gcloud auth activate-service-account --key-file /tmp/service-account.json

# TODO - switch this depending on the gkeTemplate value
# create GKE cluster (based on "Your first cluster" template)
gcloud beta container --project $project clusters create "$project-gke" --zone $zone \
 --no-enable-basic-auth --cluster-version $kubeVersion --machine-type "g1-small" --image-type "COS" \
 --disk-type "pd-standard" --disk-size "30" \
 --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
 --num-nodes $nodeCount --no-enable-cloud-logging --no-enable-cloud-monitoring --enable-ip-alias \
 --network "projects/$project/global/networks/default" \
 --subnetwork "projects/$project/regions/us-central1/subnetworks/default" \
 --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing \
 --enable-autoupgrade --enable-autorepair

# get Kube creds
export KUBECONFIG=/project/secrets/kube-config
gcloud container clusters get-credentials "$project-gke" --zone $zone --project $project
mkdir -p ~/.kube
cp /project/secrets/kube-config ~/.kube/config

# set up helm
kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller
helm init --service-account tiller --wait

# deploy etcd for [Compose on Kubernetes]()
kubectl create namespace compose
helm install --name etcd-operator stable/etcd-operator --namespace compose --wait
kubectl apply -f compose-etcd.yaml

# install Compose
account=$(gcloud info --format=json | jq '.config.account' --raw-output)
kubectl create clusterrolebinding "$account-cluster-admin-binding" --clusterrole=cluster-admin --user=$account
installer-linux -namespace=compose -etcd-servers=http://compose-etcd-client:2379 -tag="v0.4.23"

# generate empty compose file:
mkdir -p /project
echo 'version: "3.6"' > /project/docker-compose.yaml