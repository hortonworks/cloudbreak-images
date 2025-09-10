#!/bin/bash

TMP_GCP_IMAGE_CREATED=false

create_glcloud_compute_image() {
  : ${GCP_STORAGE_BUNDLE?= required}
  : ${GCP_STORAGE_BUNDLE_LOG?= required}
  : ${GCP_ACCOUNT_FILE?= required}

  if ! [[ -f $GCP_ACCOUNT_FILE ]]; then
    echo "Account file is missing: $GCP_ACCOUNT_FILE"
    exit 2
  fi

  : ${START_TIME:=$(date +%s)}
  export START_TIME
  export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '

  : ${GCP_PROJECT:=$(cat $GCP_ACCOUNT_FILE | jq .project_id -r)}
  : ${SERVICE_ACCOUNT_EMAIL:=$(cat $GCP_ACCOUNT_FILE | jq .client_email -r)}
  : ${IMAGE_PRE_NAME:=}

  STACK_VERSION_SHORT=${STACK_TYPE}-$(echo ${STACK_VERSION} | tr -d . | cut -c1-4 )
  export TMP_GCP_IMAGE_NAME=${BASE_NAME}-$(echo ${STACK_VERSION_SHORT} | tr '[:upper:]' '[:lower:]')-$(date +%s)

  docker rm -f gcloud-config-$TMP_GCP_IMAGE_NAME || true

  echo "Checking Google Cloud SDK version ..."
  docker run google/cloud-sdk:latest gcloud version
  docker run --name gcloud-config-$TMP_GCP_IMAGE_NAME -v "${GCP_ACCOUNT_FILE}":/gcp.p12 google/cloud-sdk gcloud auth activate-service-account $SERVICE_ACCOUNT_EMAIL --key-file /gcp.p12 --project $GCP_PROJECT

  echo "Checking source tar.gz ${SOURCE_IMAGE} in project $GCP_PROJECT under gs://${GCP_STORAGE_BUNDLE} ..."
  if docker run --rm --name gcloud-pre-check-$TMP_GCP_IMAGE_NAME --volumes-from gcloud-config-$TMP_GCP_IMAGE_NAME google/cloud-sdk gsutil ls gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${SOURCE_IMAGE}.tar.gz 2>/dev/null; then
    echo ${SOURCE_IMAGE}.tar.gz found.
    docker rm -f gcloud-create-instance-$TMP_GCP_IMAGE_NAME || true
    echo "Creating GCP compute image $TMP_GCP_IMAGE_NAME from $SOURCE_IMAGE.tar.gz ..."
    docker run --rm --name gcloud-create-instance-$TMP_GCP_IMAGE_NAME --volumes-from gcloud-config-$TMP_GCP_IMAGE_NAME google/cloud-sdk gcloud compute images create --quiet ${TMP_GCP_IMAGE_NAME} --source-uri gs://${GCP_STORAGE_BUNDLE}/${IMAGE_PRE_NAME}${SOURCE_IMAGE}.tar.gz --guest-os-features "UEFI_COMPATIBLE,MULTI_IP_SUBNET"
    TMP_GCP_IMAGE_CREATED=true
  else
    echo ${SOURCE_IMAGE}.tar.gz cannot be found.
    exit 1
  fi

  echo "Changing source image refernce to temporarily created image $TMP_GCP_IMAGE_NAME ..."
  SOURCE_IMAGE=$TMP_GCP_IMAGE_NAME
}

remove_glcoud_compute_image() {
  if [ "$TMP_GCP_IMAGE_CREATED" = true ]; then
    echo "Removing compute image $TMP_GCP_IMAGE_NAME ..."
    docker run --rm --name gcloud-remove-compute-image-$TMP_GCP_IMAGE_NAME --volumes-from gcloud-config-$TMP_GCP_IMAGE_NAME google/cloud-sdk gcloud compute images delete --quiet $TMP_GCP_IMAGE_NAME
  fi
  docker rm gcloud-config-$TMP_GCP_IMAGE_NAME
}

packer_in_container() {
  local dockerOpts=""
  local packerFile="./scripts/changelog/packer.json"
  PACKER_VERSION="1.8.3"

  if [[ "$GCP_ACCOUNT_FILE" ]]; then
    dockerOpts="$dockerOpts -v $GCP_ACCOUNT_FILE:$GCP_ACCOUNT_FILE"
  fi

  TTY_OPTS="--tty"
  if [[ "$JENKINS_HOME" ]]; then
    ## dont try to use docker tty on jenkins
    TTY_OPTS=""
  fi

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i $TTY_OPTS --rm \
    -e CHECKPOINT_DISABLE=1 \
    -e OS=$OS \
    -e SOURCE_IMAGE=$SOURCE_IMAGE \
    -e IMAGE_UUID="$IMAGE_UUID" \
    -e IMAGE_NAME=$IMAGE_NAME \
    -e IMAGE_SIZE=$IMAGE_SIZE \
    -e SUBNET_ID="$SUBNET_ID" \
    -e VPC_ID="$VPC_ID" \
    -e OWNER_TAG=$OWNER_TAG \
    -e IMAGE_OWNER_TAG=$IMAGE_OWNER_TAG \
    -e GCP_ACCOUNT_FILE=$GCP_ACCOUNT_FILE \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e VIRTUAL_NETWORK_RESOURCE_GROUP_NAME=$VIRTUAL_NETWORK_RESOURCE_GROUP_NAME \
    -e AWS_INSTANCE_TYPE="$AWS_INSTANCE_TYPE" \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_SNAPSHOT_GROUPS=$AWS_SNAPSHOT_GROUPS \
    -e PLAN_NAME=$PLAN_NAME \
    -e TMPDIR=/var/tmp/ \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD \
    -w $PWD \
    $dockerOpts \
    hashicorp/packer:$PACKER_VERSION "$@" $packerFile
}

main() {
  echo $IMAGE_NAME

  if [[ $CLOUD_PROVIDER == "GCP" ]]; then
    trap remove_glcoud_compute_image EXIT
    create_glcloud_compute_image
  fi

  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
