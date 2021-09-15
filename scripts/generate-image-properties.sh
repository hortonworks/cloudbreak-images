#!/bin/bash
#Used variables:
# - BASE_NAME
# - STACK_TYPE
# - STACK_VERSION
# - BUILD_ID

STACK_VERSION_SHORT=${STACK_TYPE}-$(echo ${STACK_VERSION} | tr -d . | cut -c1-4 )
IMAGE_NAME=${BASE_NAME}-$(echo ${STACK_VERSION_SHORT} | tr '[:upper:]' '[:lower:]')-$(date +%s)

echo IMAGE_NAME=${IMAGE_NAME} >> image.properties
echo METADATA_FILENAME_POSTFIX=${BUILD_ID} >> image.properties