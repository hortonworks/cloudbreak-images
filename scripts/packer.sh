#!/bin/bash

packer_in_container() {
  local dockerOpts=""

  if [[ "$GCP_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCP_ACCOUNT_FILE:$GCP_ACCOUNT_FILE"
  fi

  if [[ "$AZURE_PUBLISH_SETTINGS" ]]; then
    dockerOpts="$dockerOpts -v $AZURE_PUBLISH_SETTINGS:$AZURE_PUBLISH_SETTINGS"
  fi
  
  [[ "$TRACE" ]] && set -x
  docker run -i --rm \
    -e MOCK=$MOCK \
    -e PACKER_LOG=$PACKER_LOG \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AZURE_PUBLISH_SETTINGS=$AZURE_PUBLISH_SETTINGS \
    -e AZURE_SUBSCRIPTION_NAME=$AZURE_SUBSCRIPTION_NAME \
    -e GCP_ACCOUNT_FILE=$GCP_ACCOUNT_FILE \
    -e OS_IMAGE_NAME=$OS_IMAGE_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_TENANT_NAME=$OS_TENANT_NAME \
    -e OS_USERNAME=$OS_USERNAME \
    -e IMAGE_NAME_SUFFIX=$IMAGE_NAME_SUFFIX \
    -e ATLAS_TOKEN=$ATLAS_TOKEN \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:/data \
    -w /data \
    $dockerOpts \
    sequenceiq/packer:0.8.7-v1 "$@"
    set +x
}

main() {
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
