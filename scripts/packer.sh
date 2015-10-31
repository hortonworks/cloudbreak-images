#!/bin/bash

packer_in_container() {
  local dockerOpts=""

  if [[ "$GCE_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCE_ACCOUNT_FILE:$GCE_ACCOUNT_FILE"
  fi

  if [[ "$AZURE_PUBLISH_SETTINGS" ]]; then
    dockerOpts="$dockerOpts -v $AZURE_PUBLISH_SETTINGS:$AZURE_PUBLISH_SETTINGS"
  fi
  
  [[ "$TRACE" ]] && set -x
  docker run -i --rm \
    -e MOCK=$MOCK \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AZURE_PUBLISH_SETTINGS=$AZURE_PUBLISH_SETTINGS \
    -e AZURE_SUBSCRIPTION_NAME=$AZURE_SUBSCRIPTION_NAME \
    -e GCE_ACCOUNT_FILE=$GCE_ACCOUNT_FILE \
    -e IMAGE_NAME_SUFFIX=$IMAGE_NAME_SUFFIX \
    -e ATLAS_TOKEN=$ATLAS_TOKEN \
    -v $PWD:/data \
    -w /data \
    $dockerOpts \
    sequenceiq/packer:0.8.7-mock "$@"
    set +x
}

main() {
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
