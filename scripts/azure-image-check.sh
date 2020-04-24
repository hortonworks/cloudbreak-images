#!/bin/bash

set -e

[[ $DEBUG ]] && set -x

: "${AZURE_STORAGE_ACCOUNTS:?Storage account list must be provided}"
: "${AZURE_IMAGE_NAME:?Image name must be specified}"
: ${AZURE_IMAGE_SIZE_GB:=30}

min_image_size_in_bytes=$((AZURE_IMAGE_SIZE_GB*1024*1024*1024))
echo "Min size: $min_image_size_in_bytes"

IFS=',' read -ra STORAGE_ACCOUNTS <<< "$AZURE_STORAGE_ACCOUNTS"

for sa in "${STORAGE_ACCOUNTS[@]}"; do
	account_name=$(echo "$sa" | cut -d":" -f 2)
	url="https://${account_name}.blob.core.windows.net/images/${AZURE_IMAGE_NAME}.vhd"
	echo "==================="
	echo "Check URL: $url"
	size=$(curl -sI "$url" | grep -i Content-Length | awk '{print $2}' | tr -d '\r')
	echo "Size: $size"
	if (( size >= min_image_size_in_bytes )); then
		echo "File in account: $account_name is larger than $AZURE_IMAGE_SIZE_GB GB"
	else
		echo "File in account: $account_name is smaller than $AZURE_IMAGE_SIZE_GB GB"
		exit 1
	fi
done