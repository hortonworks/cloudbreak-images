#!/bin/bash

set -ex -o pipefail

if [ -z "$AZURE_IMAGE_NAME" ]; then
  AZURE_IMAGE_NAME=$(ls *_manifest.json | grep -q -E '_[0-9]*_manifest.json' && ls *_manifest.json | sed 's/_[0-9]*_manifest.json//' || ls *_manifest.json | sed 's/_manifest.json//')
  if [ -z "$AZURE_IMAGE_NAME" ]; then
    echo "Image name was not provided and could not be guessed from manifest.json"
    exit 1
  fi
fi

if [ -z "$AZURE_VM_GEN" ]; then
  AZURE_VM_GEN=1
fi

docker run -i --rm \
    -v $PWD:/work \
    -w /work \
    -e TRACE=$TRACE \
    -e ARM_CLIENT_ID=$ARM_CLIENT_ID \
    -e ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET \
    -e ARM_GROUP_NAME=$ARM_GROUP_NAME \
    -e ARM_STORAGE_ACCOUNT=$ARM_STORAGE_ACCOUNT \
    -e ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID \
    -e ARM_TENANT_ID=$ARM_TENANT_ID \
    -e ARM_DESTINATION_IMAGE_PREFIX=$ARM_DESTINATION_IMAGE_PREFIX \
    -e ARM_USERNAME=$ARM_USERNAME \
    -e ARM_PASSWORD=$ARM_PASSWORD \
    -e AZURE_STORAGE_ACCOUNTS="$AZURE_STORAGE_ACCOUNTS" \
    -e AZURE_IMAGE_NAME="$AZURE_IMAGE_NAME" \
    -e AZURE_VM_GEN="$AZURE_VM_GEN" \
    --entrypoint "/bin/bash" \
    docker-sandbox.infra.cloudera.com/cloudbreak-tools/cloudbreak-azure-cli-tools:1.26.0 -c ./scripts/azure-copy-managed-internal.sh

