#!/bin/bash

AZURE_IMAGE_PUBLISHER=$1
AZURE_IMAGE_OFFER=$2
AZURE_IMAGE_SKU=$3

docker run -i --rm \
    -v $PWD:/work \
    -w /work \
    -e TRACE=$TRACE \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e AZURE_IMAGE_PUBLISHER=$AZURE_IMAGE_PUBLISHER \
    -e AZURE_IMAGE_OFFER=$AZURE_IMAGE_OFFER \
    -e AZURE_IMAGE_SKU=$AZURE_IMAGE_SKU \
    --entrypoint azure-get-vm-image-version \
    hortonworks/cloudbreak-azure-cli-tools:latest 1>&2

cat azure_get_vm_image_version.out