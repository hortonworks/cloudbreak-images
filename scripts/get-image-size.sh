#!/bin/bash

source scripts/utils.sh

CLOUD_PROVIDER=$1
OS=$2
STACK_VERSION=$3
ARCHITECTURE=$4

if [[ -n "$STACK_VERSION" ]]; then
  # runtime image
  compare_version $STACK_VERSION 7.2.18
  COMP_RESULT=$?
  if [[ "$CLOUD_PROVIDER" == "AWS_GOV" ]]; then
    IMAGE_SIZE=72
  elif [[ "$CLOUD_PROVIDER" == "Azure" ]]; then
    IMAGE_SIZE=75
  elif [[ $COMP_RESULT -lt 2 ]]; then
    # stack version >= 7.2.18
    IMAGE_SIZE=64
  else
    IMAGE_SIZE=48
  fi
else
  # freeipa and base image
  if [[ "$CLOUD_PROVIDER" == "Azure" ]]; then
    IMAGE_SIZE=64
  elif [[ "$CLOUD_PROVIDER" == "Openstack" ]]; then
    IMAGE_SIZE=10
  else
    IMAGE_SIZE=48
  fi
fi

echo $IMAGE_SIZE
