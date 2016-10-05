#!/bin/bash

packer_in_container() {
  local dockerOpts=""

  if [[ "$GCP_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCP_ACCOUNT_FILE:$GCP_ACCOUNT_FILE"
  fi

  if [[ "$AZURE_PUBLISH_SETTINGS" ]]; then
    dockerOpts="$dockerOpts -v $AZURE_PUBLISH_SETTINGS:$AZURE_PUBLISH_SETTINGS"
  fi

  export CBD_VERSION_WITHOUT_PRE_RELEASE=$(echo $CBD_VERSION | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\(-[a-z]\+\)\?')
  
  echo "CBD_VERSION_WITHOUT_PRE_RELEASE: $CBD_VERSION_WITHOUT_PRE_RELEASE"

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i --rm \
    -e ORIG_USER=$USER \
    -e MOCK=$MOCK \
    -e CBD_VERSION=$CBD_VERSION \
    -e CBD_VERSION_UNDERSCORE=$CBD_VERSION_UNDERSCORE \
    -e CBD_VERSION_WITHOUT_PRE_RELEASE=$CBD_VERSION_WITHOUT_PRE_RELEASE \
    -e CHECKPOINT_DISABLE=1 \
    -e PACKER_LOG=$PACKER_LOG \
    -e PACKER_LOG_PATH=$PACKER_LOG_PATH \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AZURE_PUBLISH_SETTINGS=$AZURE_PUBLISH_SETTINGS \
    -e AZURE_SUBSCRIPTION_NAME=$AZURE_SUBSCRIPTION_NAME \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e GCP_ACCOUNT_FILE=$GCP_ACCOUNT_FILE \
    -e OS_IMAGE_NAME=$OS_IMAGE_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_TENANT_NAME=$OS_TENANT_NAME \
    -e OS_USERNAME=$OS_USERNAME \
    -e IMAGE_NAME_SUFFIX=$IMAGE_NAME_SUFFIX \
    -e ATLAS_TOKEN=$ATLAS_TOKEN \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:/$PWD \
    -w $PWD \
    $dockerOpts \
    sequenceiq/packer:v0.8.7-v10 "$@"
}

main() {
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
