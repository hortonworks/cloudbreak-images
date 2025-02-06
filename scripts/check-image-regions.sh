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

if [ -z "${OS}" ] ; then
  echo "OS env variable is mandatory."
  exit 1
fi

if [ -z "${IMAGE_REGIONS}" ] ; then
  echo "IMAGE_REGIONS env variable is mandatory."
  exit 1
fi

function trim_region() {
  local provider="$1"
  local region="$2"
  case "$provider" in
    AWS)
      retVal="$(echo "$region" | sed -e 's/^[[:space:]]*//')"
      ;;
    Azure)
      retVal="$(echo "$region" | cut -d":" -f 1 | sed -e 's/^[[:space:]]*//')"
      ;;
    *)
      echo Unexpected provider
      exit 1
  esac
  echo $retVal
}

case "$CLOUD_PROVIDER" in
  AWS)
    ALL_REGIONS=$AWS_AMI_REGIONS
    ;;
  Azure)
    case "$OS" in
      centos7)
        ALL_REGIONS=$AZURE_STORAGE_ACCOUNTS
        ;;
      redhat8)
        ALL_REGIONS="default"
        ;;
      *)
        echo "Unexpected OS: $OS"
        exit 1
    esac
    ;;
  *)
    echo "Unexpected CLOUD_PROVIDER: $CLOUD_PROVIDER"
    exit 1
esac

echo "Current image regions: $IMAGE_REGIONS"
echo "Required image regions: $ALL_REGIONS"

declare -a TRIMMED_ALL_REGIONS_ARRAY=()
IFS=',' read -ra ALL_REGIONS_ARRAY <<< "$ALL_REGIONS"
for region in "${ALL_REGIONS_ARRAY[@]}"; do
  TRIMMED_ALL_REGIONS_ARRAY+=("$(trim_region "$CLOUD_PROVIDER" "$region")")
done
IFS=$'\n' EXPECTED_REGIONS=($(sort <<<"${TRIMMED_ALL_REGIONS_ARRAY[*]}")); unset IFS

declare -a TRIMMED_IMAGE_REGIONS_ARRAY=()
IFS=',' read -ra IMAGE_REGIONS_ARRAY <<< "$IMAGE_REGIONS"
for region in "${IMAGE_REGIONS_ARRAY[@]}"; do
  TRIMMED_IMAGE_REGIONS_ARRAY+=("$(trim_region "$CLOUD_PROVIDER" "$region")")
done
IFS=$'\n' CURRENT_REGIONS=($(sort <<<"${TRIMMED_IMAGE_REGIONS_ARRAY[*]}")); unset IFS

REGIONS_1=${EXPECTED_REGIONS[@]};
REGIONS_2=${CURRENT_REGIONS[@]};
if [ "$REGIONS_1" != "$REGIONS_2" ]; then
  echo "Image does not contain all required regions"
  DIFF=$(printf '%s\n' "${EXPECTED_REGIONS[@]}" "${CURRENT_REGIONS[@]}" | sort | uniq -u)
  echo "Missing: $DIFF"
  exit 1
else
  echo "All required regions are found"
fi