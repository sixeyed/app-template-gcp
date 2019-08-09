#!/bin/sh
mkdir -p /project/secrets

# parse parameters
parameters=$(jq -c '.services | map(select(.serviceId == "gcp"))[0].parameters' /run/configuration)
saKeyEncoded=$(echo "$parameters" | jq -c '.saKeyEncoded' --raw-output)
project=$(echo "$parameters" | jq -c '.project' --raw-output)
zone=$(echo "$parameters" | jq -c '.zone' --raw-output)

# authenticate - incoming key is base64
echo $saKeyEncoded | base64 -d > /project/secrets/service-account.json
gcloud auth activate-service-account --key-file /project/secrets/service-account.json

# generate empty compose file:
mkdir -p /project
echo 'version: "3.6"' > /project/docker-compose.yaml
