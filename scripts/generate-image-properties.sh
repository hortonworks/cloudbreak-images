#!/bin/bash
#Used variables:
# - BASE_NAME
# - STACK_TYPE
# - STACK_VERSION
# - BUILD_ID

if [[ "$BASE_NAME" == "freeipa" ]]; then    # Omit STACK_VERSION_SHORT for freeipa
    IMAGE_NAME=${BASE_NAME}-$(date +%s%3N)
else
    # Original logic for all other base names
    STACK_VERSION_SHORT=${STACK_TYPE}-$(echo ${STACK_VERSION} | tr -d . | cut -c1-4 )
    IMAGE_NAME=${BASE_NAME}-$(echo ${STACK_VERSION_SHORT} | tr '[:upper:]' '[:lower:]')-$(date +%s%3N)
fi

echo IMAGE_NAME=${IMAGE_NAME} >> image.properties
echo METADATA_FILENAME_POSTFIX=${BUILD_ID} >> image.properties