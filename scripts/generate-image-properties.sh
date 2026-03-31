#!/bin/bash
#Used variables:
# - BASE_NAME
# - STACK_TYPE
# - STACK_VERSION
# - BUILD_ID


LONG_EPOCH=$(date +%s%3N)

if [[ "$BASE_NAME" == "freeipa" ]]; then
    # Omit middle section for freeipa
    IMAGE_NAME="freeipa-${LONG_EPOCH}"
else
    if [[ -z "$STACK_VERSION" ]]; then
        # STACK_VERSION is empty: do NOT include middle section
        IMAGE_NAME="base-${LONG_EPOCH}"
    else
        # STACK_VERSION exists: include the middle section
        # Note: Added tr to lowercase the STACK_TYPE as well for consistency
        STACK_VERSION_SHORT=$(echo "${STACK_VERSION}" | tr -d . | cut -c1-4 | tr '[:upper:]' '[:lower:]')
        IMAGE_NAME="cdp-${STACK_VERSION_SHORT}-${LONG_EPOCH}"
    fi
fi


# Debug @hack
IMAGE_NAME=base-1774962462880
echo "IMAGE_NAME=${IMAGE_NAME}" >> image.properties
echo "METADATA_FILENAME_POSTFIX=${BUILD_ID}" >> image.properties