#!/bin/bash

set -e

count=0

while IFS=$'\t' read -r name namespace annotation
do
  IFS="/"
  set $annotation
  AWS_ACCOUNT=$1
  AWS_DEFAULT_REGION=$2
  registry="$AWS_ACCOUNT.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
  echo "updating $namespace/$name: $AWS_ACCOUNT $AWS_DEFAULT_REGION $registry"
  password=$(aws ecr get-login-password --region $AWS_DEFAULT_REGION)
  auth=$(echo "AWS:$password" | base64)
  dockerconfig=$(jq -n ".auths[\"$registry\"].auth = \"$auth\"" | base64)
  patch=$(jq -n ".data[\".dockerconfigjson\"] = \"$dockerconfig\"")
  kubectl patch -n $namespace secret $name -p $patch
  ((count++))
done < <( \
  kubectl get -A secrets -o json \
  | jq -r '.items[].metadata | select(.annotations | has("deft.com/kubeecr")) | [.name, .namespace, .annotations."deft.com/kubeecr"] | @tsv' \
)

echo "updates complete: $count secrets updated"
