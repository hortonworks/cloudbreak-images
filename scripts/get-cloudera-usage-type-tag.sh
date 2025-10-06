#!/bin/bash

IMAGE_OWNER_TAG="$1"
RELEASE_ID_TAG="$2"

if [[ -n $IMAGE_OWNER_TAG ]]; then
  IMAGE_OWNER_TAG=$(echo ${IMAGE_OWNER_TAG,,} | tr -cd 'a-z0-9')
  if [[ -z $IMAGE_OWNER_TAG ]]; then
    echo "Specified image owner contains only characters that cannot be used."
    exit 1
  fi
else
  echo "It is mandatory to provide the image owner."
  exit 1
fi

if [[ -n $RELEASE_ID_TAG ]]; then
  if [[ "$RELEASE_ID_TAG" =~ ^[a-zA-Z]+-[0-9]+$ ]]; then
    RELEASE_ID_TAG=$(echo ${RELEASE_ID_TAG,,} | tr -d '-')
  else
    echo "Specified release identifier is not in the expected format."
    exit 1
  fi
fi

echo "cb-images-$RELEASE_ID_TAG-$IMAGE_OWNER_TAG"
