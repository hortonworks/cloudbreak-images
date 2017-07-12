#!/bin/bash

set -x

: ${ARM_USERNAME:?"need to set ARM_USERNAME"}
: ${ARM_PASSWORD:?"need to set ARM_PASSWORD"}
: ${CBD_VERSION:?"need to set CBD_VERSION"}
: ${CBD_VERSION_UNDERSCORE:?"need to set CBD_VERSION_UNDERSCORE"}

echo "CBD_VERSION_UNDERSCORE: $CBD_VERSION_UNDERSCORE"

IMAGE_NAME="$(atlas -s hortonworks/cbd/azure-arm.image --meta cbd_version=$CBD_VERSION -l | jq .metadata.short_image_name -r)"
echo "IMAGE_NAME: $IMAGE_NAME"

IMAGE_VHD=$(docker run -i --rm azuresdk/azure-cli-python:0.2.9 /bin/bash -c "az login --username $ARM_USERNAME --password $ARM_PASSWORD &> /dev/null; \
az storage blob list -c system --account-name sequenceiqnortheurope2 --prefix Microsoft.Compute/Images/packer/$IMAGE_NAME" | jq '.[0].name' -r)
echo "IMAGE_VHD: $IMAGE_VHD"

MANAGED_IMAGE_ID=$(docker run -i --rm azuresdk/azure-cli-python:0.2.9 /bin/bash -c "az login --username $ARM_USERNAME --password $ARM_PASSWORD &> /dev/null; \
az image create -g cbd-images -n $CBD_VERSION_UNDERSCORE --os-type Linux --source https://sequenceiqnortheurope2.blob.core.windows.net/system/$IMAGE_VHD" | jq '.id' -r)
echo "MANAGED_IMAGE_ID: $MANAGED_IMAGE_ID"