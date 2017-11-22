#!/bin/bash

packer_in_container() {
  local dockerOpts=""
  local packerFile="packer.json"

  if [[ "$GCP_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCP_ACCOUNT_FILE:$GCP_ACCOUNT_FILE"
  fi

  if [[ "$AZURE_PUBLISH_SETTINGS" ]]; then
    dockerOpts="$dockerOpts -v $AZURE_PUBLISH_SETTINGS:$AZURE_PUBLISH_SETTINGS"
  fi

  TTY_OPTS="--tty"
  if [[ "$JENKINS_HOME" ]]; then
    ## dont try to use docker tty on jenkins
    TTY_OPTS=""
  fi

  if [[ "$ENABLE_POSTPROCESSORS" ]]; then
    echo "Postprocessors are enabled"
  else
    echo "Postprocessors are disabled"
    rm -fv packer_no_pp.json
    jq 'del(."post-processors")' packer.json > packer_no_pp.json
    packerFile="packer_no_pp.json"
  fi

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i $TTY_OPTS --rm \
    -e MOCK=$MOCK \
    -e ORIG_USER=$USER \
    -e OS=$OS \
    -e OS_TYPE=$OS_TYPE \
    -e CHECKPOINT_DISABLE=1 \
    -e PACKER_LOG=$PACKER_LOG \
    -e PACKER_LOG_PATH=$PACKER_LOG_PATH \
    -e BASE_NAME=$BASE_NAME \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_AMI_REGIONS="$AWS_AMI_REGIONS" \
    -e AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
    -e AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
    -e AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
    -e AZURE_STORAGE_ACCOUNTS="$AZURE_STORAGE_ACCOUNTS" \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e GCP_ACCOUNT_FILE=$GCP_ACCOUNT_FILE \
    -e GCP_STORAGE_BUNDLE=$GCP_STORAGE_BUNDLE \
    -e OS_IMAGE_NAME=$OS_IMAGE_NAME \
    -e OS_AUTH_URL=$OS_AUTH_URL \
    -e OS_PASSWORD=$OS_PASSWORD \
    -e OS_TENANT_NAME=$OS_TENANT_NAME \
    -e OS_USERNAME=$OS_USERNAME \
    -e IMAGE_NAME_SUFFIX=$IMAGE_NAME_SUFFIX \
    -e HDP_VERSION=$HDP_VERSION \
    -e HDP_STACK_VERSION=$HDP_STACK_VERSION \
    -e HDP_BASEURL=$HDP_BASEURL \
    -e HDP_REPOID=$HDP_REPOID \
    -e IMAGE_NAME=$IMAGE_NAME \
    -e HDPUTIL_VERSION=$HDPUTIL_VERSION \
    -e HDPUTIL_BASEURL=$HDPUTIL_BASEURL \
    -e HDPUTIL_REPOID=$HDPUTIL_REPOID \
    -e AMBARI_VERSION=$AMBARI_VERSION \
    -e AMBARI_BASEURL=$AMBARI_BASEURL \
    -e AMBARI_GPGKEY=$AMBARI_GPGKEY \
    -e ATLAS_TOKEN=$ATLAS_TOKEN \
    -e SALT_INSTALL_OS=$SALT_INSTALL_OS \
    -e SALT_INSTALL_REPO=$SALT_INSTALL_REPO \
    -e ATLAS_ARTIFACT_TYPE=$ATLAS_ARTIFACT_TYPE \
    -e COPY_AWS_MARKETPLACE_EULA=$COPY_AWS_MARKETPLACE_EULA \
    -e CUSTOM_IMAGE_TYPE=$CUSTOM_IMAGE_TYPE \
    -e OPTIONAL_STATES=$OPTIONAL_STATES \
    -e ORACLE_JDK8_URL_RPM=$ORACLE_JDK8_URL_RPM \
    -e PREINSTALLED_JAVA_HOME=$PREINSTALLED_JAVA_HOME \
    -e DESCRIPTION="$DESCRIPTION" \
    -v $HOME/.aws:/root/.aws \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD \
    -w $PWD \
    $dockerOpts \
    hashicorp/packer:0.12.2 "$@" $packerFile
}

main() {
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
