#!/bin/bash

if [ -z "$AZURE_IMAGE_NAME" ]; then
  AZURE_IMAGE_NAME=$(ls *_manifest.json | grep -q -E '_[0-9]*_manifest.json' && ls *_manifest.json | sed 's/_[0-9]*_manifest.json//' || ls *_manifest.json | sed 's/_manifest.json//')
  if [ -z "$AZURE_IMAGE_NAME" ]; then
    echo "Image name was not provided and could not be guessed from manifest.json"
    exit 1
  fi
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
    --entrypoint azure-copy \
    hortonworks/cloudbreak-azure-cli-tools:1.17.0

docker run -i --rm \
    -v $PWD:/work \
    -w /work \
    --entrypoint pollprogress \
    hortonworks/cloudbreak-azure-cli-tools:1.17.0 \
    checks.yml

set -e

[[ $DEBUG ]] && set -x

: "${AZURE_STORAGE_ACCOUNTS:?Storage account list must be provided}"
: "${AZURE_IMAGE_NAME:?Image name must be specified}"
: ${AZURE_IMAGE_SIZE_GB:=30}

min_image_size_in_bytes=$((AZURE_IMAGE_SIZE_GB*1024*1024*1024))
echo "Min size: $min_image_size_in_bytes"

IFS=',' read -ra STORAGE_ACCOUNTS <<< "$AZURE_STORAGE_ACCOUNTS"
images=""

for sa in "${STORAGE_ACCOUNTS[@]}"; do
	region=$(echo "$sa" | cut -d":" -f 1)
	account_name=$(echo "$sa" | cut -d":" -f 2)
	url="https://${account_name}.blob.core.windows.net/images/${AZURE_IMAGE_NAME}.vhd"
	images+="${region}=${url},"
	echo "==================="
	echo "Check URL: $url"
	size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
	echo "Size: $size"
	if [[ -z "$size" ]]; then
		echo "Cannot determine size for: $account_name . Skipping it and proceeding..."
	elif (( size >= min_image_size_in_bytes )); then
		echo "File in account: $account_name is larger than $AZURE_IMAGE_SIZE_GB GB"
	else
		echo "File in account: $account_name is smaller than $AZURE_IMAGE_SIZE_GB GB"
		exit 1
	fi
done

images=${images%?} # remove trailing comma
echo "Image copied to regions: $images"
echo "IMAGES_IN_REGIONS=$images" > images_in_regions
