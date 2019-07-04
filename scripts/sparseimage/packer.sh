#!/bin/bash

packer_in_container() {
  local dockerOpts=""
  local packerFile="./scripts/sparseimage/packer.json"
  PACKER_VERSION="1.4.2"

  AMI_INFO=$(aws --region eu-west-1 ec2 describe-images --owners 679593333241 --filters 'Name=name,Values=CentOS Linux 7*' 'Name=state,Values=available' --query 'reverse(sort_by(Images, &CreationDate))[]' --output json | jq -r '.[0]')
  SOURCE_AMI=$(echo $AMI_INFO | jq -r .ImageId)
  SOURCE_AMI_SNAPSHOT=$(echo $AMI_INFO | jq -r '.BlockDeviceMappings[0].Ebs.SnapshotId')
  IMAGE_NAME=centos-sparse-base-image
  echo Going to use AMI $SOURCE_AMI with SnapshotId $SOURCE_AMI_SNAPSHOT...


  TTY_OPTS="--tty"
  if [[ "$JENKINS_HOME" ]]; then
    ## dont try to use docker tty on jenkins
    TTY_OPTS=""
  fi

  [[ "$TRACE" ]] && set -x
  ${DRY_RUN:+echo ===} docker run -i $TTY_OPTS --rm \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
    -e AWS_SUBNET_ID=$SUBNET_ID \
    -e AWS_VPC_ID=$VPC_ID \
    -e IMAGE_NAME=$IMAGE_NAME \
    -e IMAGE_OWNER=$IMAGE_OWNER \
    -e SOURCE_AMI=$SOURCE_AMI \
    -e SOURCE_AMI_SNAPSHOT=$SOURCE_AMI_SNAPSHOT \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PWD:$PWD \
    -w $PWD \
    $dockerOpts \
    hashicorp/packer:$PACKER_VERSION "$@" $packerFile
}

main() {
  packer_in_container "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
