#!/bin/bash

set -e

kubectl get -A secrets -o json \
  | jq -r '.items[].metadata | select(.annotations | has("deft.com/kubeecr")) | [.name, .namespace, .annotations."deft.com/kubeecr"] | @tsv' \
  | while IFS=$'\t' read -r name namespace annotation
  do
    IFS="/"
    set $annotation
    AWS_ACCOUNT=$1
    AWS_REGION=$2
    password=$(aws ecr get-login-password)
    registry="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
    auth=$(echo "AWS:$password" | base64)
    dockerconfig=$(jq -n ".auths[\"$registry\"].auth = \"$auth\"" | base64)
    patch=$(jq -n ".data[\".dockerconfigjson\"] = \"$dockerconfig\"")
    kubectl patch -n $namespace secret $name -p $patch
  done
