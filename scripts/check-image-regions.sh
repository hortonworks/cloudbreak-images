#!/bin/bash

if [ -z "${AWS_AMI_REGIONS}" ] ; then
  echo "AWS_AMI_REGIONS env variable is mandatory."
  exit 1
fi

if [ -z "${AZURE_STORAGE_ACCOUNTS}" ] ; then
  echo "AZURE_STORAGE_ACCOUNTS env variable is mandatory."
  exit 1
fi

if [ -z "${CLOUD_PROVIDER}" ] ; then
  echo "CLOUD_PROVIDER env variable is mandatory."
  exit 1
fi

if [ -z "${IMAGE_REGIONS}" ] ; then
  echo "IMAGE_REGIONS env variable is mandatory."
  exit 1
fi

case "$CLOUD_PROVIDER" in
  AWS)
    ALL_REGIONS=$AWS_AMI_REGIONS
    ;;
  Azure)
    ALL_REGIONS=$AZURE_STORAGE_ACCOUNTS
    ;;
  *)
    echo Unexpected CLOUD_PROVIDER
    exit 1
esac

ALL_REGIONS_ARRAY=(${ALL_REGIONS//,/ })
IFS=$'\n' EXPECTED_REGIONS=($(sort <<<"${ALL_REGIONS_ARRAY[*]}")); unset IFS
IMAGE_REGIONS_ARRAY=(${IMAGE_REGIONS//,/ })
IFS=$'\n' CURRENT_REGIONS=($(sort <<<"${IMAGE_REGIONS_ARRAY[*]}")); unset IFS

REGIONS_1=${EXPECTED_REGIONS[@]};
REGIONS_2=${CURRENT_REGIONS[@]};
if [ "$REGIONS_1" != "$REGIONS_2" ]; then
  echo "Image does not contain all required regions"
  DIFF=$(echo ${EXPECTED_REGIONS[@]} ${CURRENT_REGIONS[@]} | tr ' ' '\n' | sort | uniq -u)
  echo "Missing: $DIFF"
  exit 1
else
  echo "All required regions are found"
fi