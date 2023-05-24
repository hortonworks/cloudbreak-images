#!/bin/bash

packer_in_container() {
  local dockerOpts=""
  local packerFile="./scripts/sparseimage/packer.json"
  : "${PACKER_VERSION:="1.4.2"}"
  echo "Using Packer version $PACKER_VERSION"

  # Figure out the AMI of the previous build
  if [[ -f $(ls -1tr *_manifest.json | tail -1) ]]; then
    REGION=$(jq -r '.builds[0].artifact_id | split(",")[0] | split(":")[0]' $(ls -1tr *_manifest.json | tail -1))
    SOURCE_AMI=$(jq -r '.builds[0].artifact_id | split(",")[0] | split(":")[1]' $(ls -1tr *_manifest.json | tail -1))
  else
    echo "There is no image burnt with name $IMAGE_NAME"
    exit -1
  fi
  AMI_INFO=$(aws ec2 describe-images --region $REGION --image-ids $SOURCE_AMI --output json | jq -r '.Images[0]')
  # Figure out the snapshot id of the previous build
  SOURCE_AMI_SNAPSHOT=$(echo $AMI_INFO | jq -r '.BlockDeviceMappings[0].Ebs.SnapshotId')
  echo Going to use AMI $SOURCE_AMI with SnapshotId $SOURCE_AMI_SNAPSHOT...

  case "$REGION" in
    *gov*) AMI="ami-d8b30db9";;
    *) AMI="ami-b20542d2";;
  esac


  TTY_OPTS="--tty"
  if [[ "$JENKINS_HOME" ]]; then
    ## dont try to use docker tty on jenkins
    TTY_OPTS=""
  fi

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i $TTY_OPTS --rm \
    -e GIT_REV=$GIT_REV \
    -e GIT_BRANCH=$GIT_BRANCH \
    -e GIT_TAG=$GIT_TAG \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_SECURITY_TOKEN=$AWS_SECURITY_TOKEN \
    -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
    -e AWS_SUBNET_ID=$SUBNET_ID \
    -e AWS_VPC_ID=$VPC_ID \
    -e AWS_AMI_REGIONS="$AWS_AMI_REGIONS" \
    -e AWS_REGION="$REGION" \
    -e AWS_AMI="$AMI" \
    -e IMAGE_NAME=$IMAGE_NAME \
    -e IMAGE_OWNER=$IMAGE_OWNER \
    -e IMAGE_SIZE=$IMAGE_SIZE \
    -e ROOT_VOLUME_SIZE=$((2*IMAGE_SIZE)) \
    -e SOURCE_AMI=$SOURCE_AMI \
    -e SOURCE_AMI_SNAPSHOT=$SOURCE_AMI_SNAPSHOT \
    -e AWS_SNAPSHOT_GROUPS="$AWS_SNAPSHOT_GROUPS" \
    -e AWS_AMI_GROUPS="$AWS_AMI_GROUPS" \
    -e AWS_POLL_DELAY_SECONDS=30 \
    -e AWS_MAX_ATTEMPTS=3000 \
    -e AWS_TIMEOUT_SECONDS=3000 \
    -e PACKER_LOG=$PACKER_LOG \
    -e METADATA_FILENAME_POSTFIX="$METADATA_FILENAME_POSTFIX" \
    -e IMAGE_UUID="$IMAGE_UUID" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD \
    -w $PWD \
    $dockerOpts \
    hashicorp/packer:$PACKER_VERSION "$@" $packerFile
}

main() {
  echo $IMAGE_NAME
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
