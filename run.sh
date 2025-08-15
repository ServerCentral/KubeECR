#!/bin/bash

if [[ $KUBEECR_DEBUG ]]
then
  set -euxo pipefail
else
  set -e
fi

echo "Running KubeECR"
echo "Account: ${AWS_ACCOUNT:?AWS_ACCOUNT is required}"
echo "Region: ${AWS_REGION:?AWS_REGION is required}"
echo "Selector: ${KUBEECR_SELECTOR:?KUBEECR_SELECTOR is required}"

if [[ -n $KUBEECR_NAMESPACE ]]
then
  echo "Namespace: $KUBEECR_NAMESPACE"
  export ns_filter="-n $KUBEECR_NAMESPACE"
else
  echo "All Namespaces"
  export ns_filter="-A"
fi

while IFS=$'\t' read -r name namespace
do
  registry="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
  echo "Updating secret $namespace/$name for registry: $registry"
  password=$(aws ecr get-login-password)
  auth=$(echo -n "AWS:$password" | base64)
  dockerconfig=$(jq -cn ".auths[\"$registry\"].auth = \"$auth\"" | base64)
  patch=$(jq -cn ".data[\".dockerconfigjson\"] = \"$dockerconfig\"")
  kubectl patch -n $namespace secret $name -p "$patch"
done < <( \
  kubectl get $ns_filter secrets -l "$KUBEECR_SELECTOR" -o json \
  | jq -r '.items[].metadata | [.name, .namespace] | @tsv' \
)

exit 0
