#!/bin/bash

source scripts/utils.sh

CLOUD_PROVIDER=$1
OS=$2
STACK_VERSION=$3

if [ "$OS" == "centos7" ]; then
  if [ "$CLOUD_PROVIDER" == "GCP" ]; then
    IMAGE_SIZE=48
  else
    IMAGE_SIZE=36
  fi
else
  compare_version $STACK_VERSION 7.2.18
  COMP_RESULT=$?
  if [[ "$CLOUD_PROVIDER" == "Azure" ]]; then
    IMAGE_SIZE=64
  elif [[ $COMP_RESULT -lt 2 ]]; then
    # stack version >= 7.2.18
    IMAGE_SIZE=52
  else
    IMAGE_SIZE=48
  fi
fi

echo $IMAGE_SIZE
