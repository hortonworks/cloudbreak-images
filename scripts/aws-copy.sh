#!/bin/bash

set -ex -o pipefail

log() {
  echo "$(date --rfc-3339=seconds) $1"
}

AMI_ID=${IMAGE_NAME:-}
if [ -z "$AMI_ID" ]; then
  log "ERROR: IMAGE_NAME env variable is not set!"
  exit 1
fi

log "Installing jq..."
yum install -q -y jq

TARGET_TAG_KEYS=("cloudera-usage-type" "owner")

IMAGE_DATA=$(aws ec2 describe-images --region "$SOURCE_LOCATION" --filters "Name=image-id,Values=$AMI_ID" --query 'Images[0].{Name:Name,Tags:Tags}' --output json 2>/dev/null)
IMAGE_NAME=$(echo "$IMAGE_DATA" | jq -r '.Name // empty')

if [ -z "$IMAGE_NAME" ]; then
  log "Source image $AMI_ID in region $SOURCE_LOCATION not found, exiting"
  exit 1
fi

JQ_FILTER_KEYS=$(printf '.Key == "%s" or ' "${TARGET_TAG_KEYS[@]}" | sed 's/ or $//')
AMI_TAGS=$(echo "$IMAGE_DATA" | jq -c "[.Tags[]? | select($JQ_FILTER_KEYS)] // []")
log "Filtered source tags to copy: $AMI_TAGS"

SRC_ACCOUNT=${SOURCE_ACCOUNT:-"self"}
log "Source account is $SRC_ACCOUNT"

wait_for_image_and_check() {
  local REGION=$1
  local AMI_IN_REGION=$2
  
  export AWS_RETRY_MODE=standard
  export AWS_MAX_ATTEMPTS=60
  export AWS_DELAY=60

  while true; do
    local image_status=$(aws ec2 describe-images --image-ids "$AMI_IN_REGION" --region "$REGION" --query 'Images[0].State' --output text 2>/dev/null || echo "error")
    log "Image [$AMI_IN_REGION] status is [$image_status] in region [$REGION]."
    if [ "$image_status" == "available" ]; then
      log "Image is available now. Continuing..."
      break
    elif [ "$image_status" == "pending" ]; then
      log "Waiting 30 seconds..."
      sleep 30
    else
      log "Error: Image status is $image_status, exiting..."
      return 1
    fi
  done

  log "Querying snapshot in region $REGION for image $AMI_IN_REGION"
  local SNAPSHOT_ID=$(aws ec2 describe-images --image-ids "$AMI_IN_REGION" --region "$REGION" --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --output text)

  if [ "$MAKE_PUBLIC_SNAPSHOTS" == "yes" ]; then
    log "Setting snapshot $SNAPSHOT_ID visibility to public in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-snapshot-attribute --snapshot-id "$SNAPSHOT_ID" --region "$REGION" --create-volume-permission "Add=[{Group=all}]"
  elif [ -n "$AWS_SNAPSHOT_USER" ]; then
    log "Setting snapshot $SNAPSHOT_ID visibility for user in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-snapshot-attribute --snapshot-id "$SNAPSHOT_ID" --region "$REGION" --create-volume-permission "Add=[{UserId=$AWS_SNAPSHOT_USER}]"
  fi

  if [ "$MAKE_PUBLIC_AMIS" == "yes" ]; then
    log "Setting launch permissions to public in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-image-attribute --image-id "$AMI_IN_REGION" --region "$REGION" --launch-permission "Add=[{Group=all}]"
  elif [ -n "$AWS_AMI_ORG_ARN" ]; then
    log "Setting launch permissions only for organization in region $REGION for image $AMI_IN_REGION"
    aws ec2 modify-image-attribute --image-id "$AMI_IN_REGION" --region "$REGION" --launch-permission "Add=[{OrganizationArn=$AWS_AMI_ORG_ARN}]"
  fi

  for ((i=0; i<5; i++)); do
    local IMAGESTATUS="FAILED" SNAPSTATUS="FAILED"
    local IMAGE_DESC=$(aws ec2 describe-images --region "$REGION" --image-ids "$AMI_IN_REGION" --output json)
    local IMAGE_AVAILABLE=$(echo "$IMAGE_DESC" | jq -r '.Images[0].State')

    if [ "${IMAGE_AVAILABLE}" == "available" ]; then
      log "The $AMI_IN_REGION in $REGION region is available, checking permissions..."
      local IMAGE_PUBLIC=$(echo "$IMAGE_DESC" | jq -r '.Images[0].Public')
      if [ "$MAKE_PUBLIC_AMIS" == "yes" ] && [ "${IMAGE_PUBLIC}" == "true" ]; then
        log "The $AMI_IN_REGION in $REGION region is public"
        IMAGESTATUS="OK"
      elif [ -n "$AWS_AMI_ORG_ARN" ]; then
        local IMAGE_ORGANIZATION_ARN=$(aws ec2 describe-image-attribute --region "$REGION" --image-id "$AMI_IN_REGION" --attribute launchPermission --query 'LaunchPermissions[0].OrganizationArn' --output text)
        if [ "${IMAGE_PUBLIC}" == "false" ] && [ "${IMAGE_ORGANIZATION_ARN}" == "$AWS_AMI_ORG_ARN" ]; then
          log "The $AMI_IN_REGION in $REGION region is only shared with an organization"
          IMAGESTATUS="OK"
        fi
      else
        if [ "${IMAGE_PUBLIC}" == "false" ]; then
          log "The $AMI_IN_REGION in $REGION region is private"
          IMAGESTATUS="OK"
        fi
      fi
    fi

    local SNAPSHOT_PERMISSIONS=$(aws ec2 describe-snapshot-attribute --region "$REGION" --snapshot-id "$SNAPSHOT_ID" --attribute createVolumePermission --output json)
    local SNAPSHOT_PUBLIC=$(echo "$SNAPSHOT_PERMISSIONS" | jq -r '.CreateVolumePermissions | any(.Group == "all")')
    
    if [ "$MAKE_PUBLIC_SNAPSHOTS" == "yes" ] && [ "${SNAPSHOT_PUBLIC}" == "true" ]; then
      SNAPSTATUS="OK"
    elif [ -n "$AWS_SNAPSHOT_USER" ]; then
      local SNAPSHOT_SHARED_WITH_USER=$(echo "$SNAPSHOT_PERMISSIONS" | jq -r --arg userId "$AWS_SNAPSHOT_USER" '.CreateVolumePermissions | any(.UserId == $userId)')
      [ "${SNAPSHOT_PUBLIC}" == "false" ] && [ "${SNAPSHOT_SHARED_WITH_USER}" == "true" ] && SNAPSTATUS="OK"
    else
      [ "${SNAPSHOT_PUBLIC}" == "false" ] && SNAPSTATUS="OK"
    fi

    if [ "${IMAGESTATUS}" == "OK" ] && [ "${SNAPSTATUS}" == "OK" ]; then
      log "Copy operation and verification in region $REGION for image $AMI_IN_REGION successfully finished."
      return 0
    fi
    sleep 60
  done

  log "FAILURE | Validation failed in region $REGION."
  return 1
}

FAILED_REGIONS_FILE="failed-regions.txt"
rm -f "$FAILED_REGIONS_FILE"
declare -A JOB_REGIONS
IMAGES=""

log "Copying image $IMAGE_NAME ($AMI_ID) from region $SOURCE_LOCATION to regions $AWS_AMI_REGIONS"

for REGION in ${AWS_AMI_REGIONS//,/ }; do
  if [ "$REGION" == "$SOURCE_LOCATION" ]; then
    log "Source and destination regions are the same, skipping copy to $REGION"
    continue
  fi

  log "Processing region $REGION..."
  TARGET_IMAGE_DATA=$(aws ec2 describe-images --owners "$SRC_ACCOUNT" --filters "Name=name,Values=$IMAGE_NAME" --region "$REGION" --query "Images[*].{ImageId:ImageId,Tags:Tags}" --output json 2>/dev/null) || true
  AMI_IN_REGION=$(echo "$TARGET_IMAGE_DATA" | jq -r '.[0].ImageId // empty')
  TAGS_TO_APPLY="$AMI_TAGS"
  
  if [ -n "$AMI_IN_REGION" ]; then
    log "Image is already copied to region $REGION as $AMI_IN_REGION"
    if [ "$AMI_TAGS" != "[]" ] && [ -n "$AMI_TAGS" ]; then
      TAGS_TO_APPLY=$(echo "$TARGET_IMAGE_DATA" | jq --argjson src_tags "$AMI_TAGS" -c '.[0].Tags // [] | map(.Key) as $dest_keys | $src_tags | map(select(.Key as $k | ($dest_keys | contains([$k]) | not)))')
    fi
  else
    AMI_IN_REGION=$(aws ec2 copy-image --source-image-id "$AMI_ID" --source-region "$SOURCE_LOCATION" --region "$REGION" --name "$IMAGE_NAME" --query "ImageId" --output text 2>/dev/null) || true
    if [ -z "$AMI_IN_REGION" ] || [[ "$AMI_IN_REGION" == *"An error occurred"* ]]; then
      log "FAILURE | Could not initiate copy to region $REGION"
      echo "$REGION" >> "$FAILED_REGIONS_FILE"
      continue
    fi
    log "Image copy started to region $REGION as $AMI_IN_REGION, waiting for its completion"    
  fi

  if [ "$TAGS_TO_APPLY" != "[]" ] && [ -n "$TAGS_TO_APPLY" ]; then
    log "Applying missing tags to $AMI_IN_REGION in region $REGION: $TAGS_TO_APPLY"
    aws ec2 create-tags --resources "$AMI_IN_REGION" --region "$REGION" --tags "$TAGS_TO_APPLY" >/dev/null 2>&1 || true
  else
    log "All target tags (${TARGET_TAG_KEYS[*]}) are already present on $AMI_IN_REGION (or none found on source), skipping tagging."
  fi

  IMAGES+="${REGION}=${AMI_IN_REGION},"

  wait_for_image_and_check "$REGION" "$AMI_IN_REGION" &
  JOB_REGIONS[$!]="$REGION"
done

log "Checking background jobs..."

for pid in "${!JOB_REGIONS[@]}"; do
  REG=${JOB_REGIONS[$pid]}
  log "Checking status of job $pid for region $REG..."
  
  set +e
  wait "$pid"
  JOB_STATUS=$?
  set -e

  log "Job $pid execution finished with status: $JOB_STATUS"
  if [ $JOB_STATUS -ne 0 ]; then
    if ! grep -q "^${REG}$" "$FAILED_REGIONS_FILE" 2>/dev/null; then
      echo "$REG" >> "$FAILED_REGIONS_FILE"
    fi
  fi
done

IMAGES=${IMAGES%?} # remove trailing comma

log "Image copy process finished."

if [ -s "$FAILED_REGIONS_FILE" ]; then
  FAILED_REGIONS=$(sort -u "$FAILED_REGIONS_FILE" | paste -sd, -)
  log "ERROR: The copy of the following regions FAILED during the process: $FAILED_REGIONS"
  exit 1
fi

log "SUCCESS: All images copied and verified successfully!"
log "Image copied to regions: $IMAGES"
echo "IMAGES_IN_REGIONS=$IMAGES" > images_in_regions